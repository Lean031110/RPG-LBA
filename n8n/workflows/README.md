# n8n workflow exports

This directory is reserved for importable n8n JSON exports. Workflows should be inactive by default and must not contain real credentials.

## Rules
- Export after every approved workflow change.
- Stable filename: NN_category_name.json.
- Every workflow must have a stable ID in n8n/WORKFLOW_INDEX.csv, version, purpose, trigger, required secrets, dependencies and test procedure.
- Never commit API tokens, private credential IDs, execution data or personal data.
- Import into a test instance first; inspect community nodes and version compatibility.
- n8n Cloud and Community Edition can differ in environment-variable access, public API and backup options.
- Credentials are created in n8n's credential manager and reassigned after import.

## Bootstrap status
No workflows have been exported from the user's real n8n instance. The n8n connector did not respond during bootstrap. Do not invent existing workflows or overwrite them. Z.ai must inspect the live instance when accessible and create the first verified exports.

See docs/art-pipeline/N8N_BACKUP_AND_MIGRATION.md.
