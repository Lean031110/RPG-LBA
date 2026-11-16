# n8n — Backup, export, import and continuity

## Principal rule
GitHub stores exported workflow definitions and documentation, but must not store credentials, live database, encryption key or secrets. A workflow JSON is not a complete backup of an n8n instance.

Current n8n Cloud trial documentation: 14 days, 1,000 executions, up to 5 concurrent executions and 180-second timeout. There is no permanent free n8n Cloud plan. Community Edition self-hosted is free under the Sustainable Use License for internal use by you/your team; do not use it to host n8n as a service for third parties or let external customers build/configure workflows without checking the license.

## Backup matrix

| Item | Destination |
|---|---|
| Workflow JSON exports without credentials | GitHub n8n/workflows/ |
| Non-secret configuration and versions | GitHub n8n/ |
| API tokens and credentials | n8n Credentials / secure secret manager |
| N8N_ENCRYPTION_KEY | Secure manager and separate encrypted recovery copy, never Git |
| n8n database (SQLite/Postgres) | Separate encrypted backup, never commit |
| Execution data | Limited retention; avoid unnecessary sensitive payloads |
| n8n/node versions | n8n/COMPATIBILITY.md |

## Workflow export
On a compatible instance, export workflows through UI or CLI. Example CLI for self-hosted n8n:

    n8n export:workflow --all --output=/secure-backup/workflows/

Review exports before committing: remove personal data and secret values from node parameters. Verify CLI flags against the exact installed n8n version.

## Credentials and encryption
- Do not export credentials in decrypted form.
- Encrypted credential backups require the exact same N8N_ENCRYPTION_KEY on the destination instance.
- Store that key outside Git, in a secure manager or encrypted offline recovery copy controlled by the owner.
- If the key is lost, reimporting workflow JSON does not decrypt old credentials.
- n8n Cloud may not expose DB/key backup controls available to self-hosted; verify plan-specific capabilities.

## Restore/migration
1. Create a compatible destination instance and pin n8n version.
2. Configure HTTPS public URL, timezone, webhooks and execution policies.
3. Import workflow JSON.
4. Create/reassign Credentials or restore an authorized encrypted credential backup.
5. Configure secrets outside workflow JSON.
6. Test workflows inactive using test data.
7. Verify Telegram, GitHub, Firebase, providers and storage destinations.
8. Activate gradually; only retire the previous instance after verification.

## Cloud account migration limitations
Workflow export/import reuses definitions; it does not automatically migrate executions, tables, credentials, projects, users, history, internal IDs or webhooks. Each Data Table must have an explicit export/import procedure and verified row counts. Never assume a new account is a full clone.

## LBA recommendation
- Treat n8n as a replaceable orchestrator.
- Do not use n8n Data Tables as the only asset inventory: keep CSV/JSON versioned in GitHub and optionally sync a projection to Firebase.
- Export workflows after each approved change and back up before migration.
- Schedule and test restore periodically.
- Do not automate account creation or repeated free-trial resets. Use a legitimate active Cloud plan or Community Edition when connectivity permits.

## Current bootstrap status
- Export/import against the user's real n8n instance: NOT TESTED (n8n connector did not respond during bootstrap).
- Database backup: NOT TESTED.
- Encryption-key backup: NOT TESTED.
- Restore into clean instance: NOT TESTED.
- Telegram/GitHub/Firebase credentials: NOT CONFIGURED.


## Límites importantes de la prueba Cloud
La tabla oficial de n8n indica que el trial Cloud actual excluye la API pública de n8n. Por tanto, no diseñar la exportación automática suponiendo que el trial permite administrar workflows mediante API. Durante el trial, usar export/import desde la interfaz cuando sea necesario; comprobar nuevamente el plan antes de automatizarlo. La prueba incluye 1.000 ejecuciones, cinco simultáneas y timeout de 180 segundos.
