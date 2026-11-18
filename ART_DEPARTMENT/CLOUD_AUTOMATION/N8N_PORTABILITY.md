# n8n portability, backup and restore

This guide preserves workflows between n8n instances. It does **not** automate creating successive trial accounts or claim that a workflow export is a full instance backup.

## 1. Cloud trial limits

As checked 15 November 2026, n8n Cloud has no permanent free plan. The standard trial lasts 14 days and offers 1,000 executions; the current pricing page also lists 5 concurrent executions and a 180-second execution timeout. The trial ends automatically. The n8n FAQ states a 3-day grace period, followed by 5 days before deletion, and says workflows can be downloaded for up to 90 days after trial end.

Do not make the asset pipeline depend on n8n Cloud being continuously available. Do not automate account creation/identity cycling to bypass a trial limit. This plan keeps GitHub Actions as the cloud control plane and makes n8n optional/importable.

## 2. What Git should contain

Safe, shareable repository content:
- workflows exported as JSON after removing real credential bindings and all secrets;
- documentation, node inventory, workflow names, expected inputs/outputs and target n8n version;
- synthetic test fixtures and validation reports;
- placeholder names for credentials that the user creates separately in n8n.

Never commit:
- credential export files, even if encrypted;
- decrypted credentials;
- the `.n8n` directory, SQLite database or PostgreSQL dump;
- the n8n `config` file;
- `N8N_ENCRYPTION_KEY`, API keys, bot tokens, OAuth refresh tokens or service-account keys;
- execution logs/binary data containing customer/user data.

The actual full backup must be stored separately in an encrypted private location or password manager-controlled storage. The project repository is public.

## 3. Backup of a self-hosted instance

A full self-hosted backup includes:
1. the complete `~/.n8n` user folder (normally mounted at `/home/node/.n8n` in Docker), which contains the configuration/encryption key and, with default SQLite, the database and execution/binary data stored on filesystem;
2. an external PostgreSQL backup when PostgreSQL is used;
3. separately configured binary/execution storage paths and custom node directories, if any.

With SQLite, stop n8n before copying `.n8n` to avoid an inconsistent database copy. With PostgreSQL, back up the database with its own tool and still preserve the `.n8n` config/key.

The encryption key is essential. Without the original key, credential records cannot be decrypted. Keep it in a password manager or a secure secret store; do not store the key next to an unencrypted backup.

## 4. Portable export of workflows and credentials

For a self-hosted n8n CLI environment:

```bash
mkdir -p backups/workflows backups/credentials

n8n export:workflow --backup --output=backups/workflows/
n8n export:credentials --backup --output=backups/credentials/
```

`--backup` means all + pretty + one file per record. Use separate directories. Credential exports contain encrypted credential data, but remain sensitive; do not add them to this public repository.

For a clean, shareable workflow export, remove credentials bindings from the JSON after exporting and replace them with a documented logical binding such as `Telegram Bot (create this in the target instance)`. Never add API tokens as string values in workflow nodes.

For n8n Cloud trial, use the Cloud console workflow download before expiry. The trial may not provide the public API; do not assume an API-based export is available.

## 5. Restore into another self-hosted instance

1. Install the same n8n major version (prefer the same exact version for the first restore).
2. Complete owner setup on the new instance.
3. Restore `.n8n`, the original encryption key and external database/storage before starting if performing a full restore.
4. If restoring workflows only, import the workflows:
   
   ```bash
   n8n import:workflow --separate --input=backups/workflows/
   ```

5. Credentials can be imported only if the same encryption key is configured, unless the user knowingly chooses an insecure decrypted migration (not recommended and never committed):
   
   ```bash
   n8n import:credentials --separate --input=backups/credentials/
   ```

6. Recreate credential bindings in the target instance if workflow exports were sanitized.
7. Imported workflows are inactive by default in common restore paths. Review each workflow, set credentials and test it before activation.
8. Run valid/invalid/duplicate test fixtures, verify outputs, then activate triggers manually.

**Important:** CLI workflow/credential exports do not include users/roles, executions/logs, variables, instance settings or the encryption key. They are enough to migrate workflows, not enough to restore a full instance.

## 6. Recommended folder layout

```text
automation/
  n8n/
    README.md
    workflows/
      README.md
      *.json              # Sanitized, importable templates only
    fixtures/
      *.json              # Synthetic test inputs, no personal data
    backup-private/
      README.md           # Instructions only; never commit backup files
```

In the private backup area keep a dated encrypted archive with:
- `.n8n` folder (or snapshot);
- PostgreSQL dump if used;
- exported workflows and encrypted credentials;
- deployment variables without secrets;
- custom node/plugin inventory;
- n8n version and restore instructions;
- SHA-256 checksum file;
- restore verification date.

## 7. When to switch from Cloud trial to Community Edition

The self-hosted Community Edition can be used for personal/internal business under n8n's Sustainable Use License, subject to its restrictions. It is not a free managed hosting plan for external customers. Your current server has no internet access, so do not make it a dependency now. Keep the portable exports in Git; when the Proxmox/Xubuntu system is eventually online, deploy CE locally and restore from private backup.

## 8. Validation checklist

- [ ] Current workflows downloaded/exported.
- [ ] Workflow JSON sanitized and validated.
- [ ] Encrypted credential backup stored outside Git.
- [ ] Original encryption key stored securely outside Git.
- [ ] Full `.n8n` and external database/storage backup completed, if self-hosted.
- [ ] Restore tested on disposable instance with synthetic inputs.
- [ ] Workflows remain inactive until credentials and dry-run results are verified.
- [ ] No token/credential file appears in Git status, PR diff or CI logs.

Official references:
- [n8n backup and restore](https://docs.n8n.io/hosting/backup/)
- [n8n CLI](https://docs.n8n.io/hosting/cli-commands/)
- [n8n Cloud trial FAQ](https://support.n8n.io/article/how-do-i-cancel-my-trial)
- [n8n pricing](https://n8n.io/pricing/)


## 9. Source control built into n8n is not a free-plan migration path

The official n8n source-control/environments feature is documented as available on **Business and Enterprise** plans. Do not design the Free Cloud trial or Community Edition workflow around that feature. Official guide: https://docs.n8n.io/administer/use-source-control-and-environments/tutorial-create-environments-with-source-control/

For this project:
- Keep sanitized workflow JSON templates under GitHub, using normal commits/PRs.
- Treat the Git repository as the canonical asset catalogue and backlog. Do not make n8n Data Tables the only place containing asset IDs, provenance, license state, job checkpoints or progress.
- If any n8n Data Tables are used, create an explicit export/import procedure per table (CSV/JSON), with table name, schema version, row count, export timestamp, checksum and restore test. The standard Cloud workflow backup export is not proof that Data Table rows, credentials, executions or other instance state are included.
- Before a Cloud trial ends, use Cloud console > Export > select backup date > Download workflows. The backup is a workflow recovery route, not a complete clone. The download is available up to 90 days after trial/subscription end; after that the backups are deleted. Official guide: https://support.n8n.io/article/how-to-export-workflows-from-the-n-8-n-cloud-admin-panel
- Public API is unavailable during the Cloud free trial. Do not build automation that expects API access on trial accounts. Official confirmation: https://support.n8n.io/article/can-i-have-api-access-while-i-am-on-a-trial

## 10. The migration test that must pass before retiring an instance

Create a fresh destination only through a legitimate plan/Community Edition deployment. Import the sanitized workflows, recreate credential bindings securely, restore private database/table exports, and run synthetic test fixtures. Compare workflow count, workflow names, table names, row counts, schema versions, active/inactive status and webhook URLs. Record a restore report and SHA-256 checksums. Do not deactivate the old instance until the new one passes. If any table or secret cannot be restored, mark it FAIL/NOT TESTED and retain the prior instance within its valid period.
