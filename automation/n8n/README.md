# n8n portable workflows for RPG LBA

The cloud-first pipeline does not depend on a running n8n account. GitHub Actions remains the primary orchestrator while the server is offline. This directory is reserved for **sanitized, importable workflow JSON templates** only.

See [n8n portability and backup](../../ART_DEPARTMENT/CLOUD_AUTOMATION/N8N_PORTABILITY.md).

## Rules

- Export workflows in JSON and keep their target n8n version documented.
- Set every example workflow to `active: false`.
- Remove bound live credentials from shareable JSON; re-create the matching n8n credentials in the destination instance.
- Never add credential export files, decrypted JSON, encryption keys, databases, .n8n backups, API tokens, OAuth tokens or Telegram bot secrets.
- Preserve workflow/node IDs when changing an existing export; do not replace a user's production workflow from a template without a backup.
- Test in a disposable n8n instance with synthetic input before activation.
- Every workflow needs positive, invalid and duplicate-event tests. Cross-execution deduplication requires durable storage / idempotency; an in-memory Set is not enough.
- Report structural validation separately from runtime verification.

When no sanitized workflow JSON has been reviewed and tested, leave this folder without production workflow templates rather than committing invented node versions.
