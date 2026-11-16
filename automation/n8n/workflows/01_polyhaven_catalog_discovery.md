# 01 — Poly Haven catalog discovery (n8n template)

Migrated from PR #19 (`agent/assets-factory-bootstrap`, file
`n8n/workflows/01_polyhaven_catalog_discovery.json`) into the single canonical
template location `automation/n8n/workflows/`. Nothing else in that PR's
`n8n/` folder survives as a canonical source; see
[PR19 reconciliation](../../../ART_DEPARTMENT/CLOUD_AUTOMATION/PR19_RECONCILIATION.md).

## Purpose

Manual, read-only discovery step: fetch the Poly Haven public asset catalog
metadata (one HTTP GET) so a human can shortlist CC0 assets before anything is
downloaded or registered in `assets/manifest.csv`.

## Trigger

`Manual start` only. The template is committed with `"active": false` and must
stay inactive until it has been imported and reviewed in a disposable n8n
instance.

## Nodes / versions

| Node | type | typeVersion | Notes |
|---|---|---|---|
| Manual start | `n8n-nodes-base.manualTrigger` | 1 | No schedule |
| Fetch Poly Haven asset metadata | `n8n-nodes-base.httpRequest` | 4.2 | GET `https://api.polyhaven.com/assets` |

Target n8n version: any recent Cloud/CE version supporting httpRequest
typeVersion 4.2 (test with the exact instance you import into; recorded target:
n8n 1.x, `executionOrder: v1`).

## Inputs / outputs

- Input: none.
- Output: Poly Haven catalog JSON (asset ids, names, categories, tags). Large
  response; inspect counts before forwarding anywhere.

## Credentials

None. The Poly Haven public API endpoints do not require a key. The request
sends an identifiable User-Agent (`RPG-LBA-AssetFactory/1.0`) as their API
etiquette requests. If n8n's HTTP node already sets its own User-Agent header,
keep the custom one and document the difference.

## Side effects / rate limits

- One outbound HTTPS GET to `api.polyhaven.com` per execution.
- No writes, no downloads, no repo changes.
- Poly Haven is a small free service: run manually, do not put this node on a
  cron tighter than daily, and keep the "Powered by Poly Haven" credit in any
  derived UI/docs as their API terms request.

## Idempotency / dedup

Read-only single GET; no state. Deduplication is not applicable. Any follow-on
workflow that registers assets must dedup by Poly Haven asset id + SHA-256 of
the downloaded file against `ASSET_LIBRARY_INDEX.json` before creating a new
row — that logic does not exist yet and must be designed before activation.

## Test plan (synthetic)

- Valid: manual run returns JSON with an `assets` object (assert non-empty count).
- Invalid: point the URL at a non-existing endpoint and confirm the node fails
  visibly (no silent empty success).
- Duplicate: run twice, confirm no side effects accumulate.

## Verification status

| Check | Result |
|---|---|
| JSON structure sanity (nodes/connections present, active=false) | PASS (static check on import to this repo) |
| Import into a real n8n instance | NOT TESTED |
| Execution against the live API | NOT TESTED |
| Rate-limit behavior | NOT TESTED |

Do not mark this template "tested" until a real import + execution is recorded
here with date and instance version.
