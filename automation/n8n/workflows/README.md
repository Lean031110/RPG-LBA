# Workflow template library

Single canonical location for sanitized, importable n8n workflow JSON
templates (this absorbs the roadmap previously tracked in PR #19's
`n8n/WORKFLOW_INDEX.csv`; that CSV is retired — see
[PR19 reconciliation](../../../ART_DEPARTMENT/CLOUD_AUTOMATION/PR19_RECONCILIATION.md)).

Each template must have a companion `.md` document including:
- workflow purpose and trigger;
- target n8n version and node/type versions;
- expected input/output payloads;
- required credential names (logical names, no secret values);
- side effects and rate limits;
- idempotency/deduplication design;
- disabled/inactive default state;
- valid, invalid and duplicate test results;
- whether it was tested by importing/running a disposable instance.

No live exports or credentials are stored here. The connected n8n instance
could not be inspected during this setup, so no claim is made that its current
workflows were exported.

## Index

| workflow_id | Template | Status | Trigger | Credentials | Dependencies | Verification |
|---|---|---|---|---|---|---|
| lba.n8n.polyhaven-catalog-discovery | [01_polyhaven_catalog_discovery.json](01_polyhaven_catalog_discovery.json) / [doc](01_polyhaven_catalog_discovery.md) | TEMPLATE_READY (inactive) | Manual | none | Poly Haven public API | Static check PASS; import/run NOT TESTED |
| lba.n8n.asset-source-scan | — | PLANNED | Manual or scheduled | none | Poly Haven API | NOT TESTED |
| lba.n8n.asset-license-audit | — | PLANNED | GitHub event or manual | GITHUB_TOKEN (read) | assets/manifest.csv | NOT TESTED |
| lba.n8n.asset-job-dispatch | — | PLANNED | Manual or queue | provider-specific | provider adapters + quota controller | NOT TESTED |
| lba.n8n.blender-process | — | PLANNED | GitHub Actions dispatch | GITHUB_TOKEN | Blender scripts + job manifest | NOT TESTED |
| lba.n8n.godot-validation | — | PLANNED | GitHub Actions dispatch | GITHUB_TOKEN | Godot 4.7.2 import + smoke tests | NOT TESTED |
| lba.n8n.telegram-review | — | PLANNED | Webhook or workflow event | TELEGRAM_BOT_TOKEN + TELEGRAM_CHAT_ID | Telegram Bot API | NOT TESTED |
| lba.n8n.backup-export | — | PLANNED | Schedule / before migration | n8n admin access | workflow exports + secure backup location | NOT TESTED |

Rules for the PLANNED rows: they are design placeholders only. GitHub Actions
remains the primary orchestrator while the local server/n8n is offline; build
the GitHub-native path first and only add the n8n equivalent when a real
instance is available to test against.
