# LBA Cloud Asset Production & Automation

**Status:** implementation blueprint + audited baseline  
**Repository:** https://github.com/Lean031110/RPG-LBA  
**Working branch:** `agent/asset-cloud-automation`  
**Main inspected at:** `83c11940d55254d7dbbd21549128ef17a0e9f5ba`  
**Engine target:** Godot 4.7.2 Standard, GDScript typed, Compatibility Renderer, Android ARM64.

This directory is the portable control plane for the art pipeline. GitHub is the source of truth for the asset catalogue, backlog, provenance, workflow definitions and review history. No local server, phone or always-on machine is required for the base pipeline.

## 1. Current audited baseline

The official `main` already contains an AI Asset Factory. Do not create a competing factory.

- `ART_DEPARTMENT/AI_ASSET_FACTORY/`: procedural generation, deterministic queue, catalogue, validation reports, CLI and previews.
- `assets/models/`: 62 procedural GLB models in the first batch.
- `assets/environment/textures/`: 21 PBR texture sets (the maps are individual PNG files).
- `assets/materials/`: 10 Godot material definitions.
- `ART_DEPARTMENT/AI_ASSET_FACTORY/catalog/assets_manifest.json`: canonical machine catalogue.
- Production report: 93/93 first-batch assets in the catalogue; technical checks and tests were reported PASS; visual human approval and in-scene/mobile validation remain separate gates.

The current inventory scan found 262 supported binary/source asset files: 198 file references associated with the 93 manifest entries, plus 64 legacy files indexed separately. The count of 198 counts file references (some logical assets contain multiple files), not 198 extra assets. The 93 catalogue entries are predominantly environment/prop assets. They do **not** mean the six player classes, all enemies, bosses and NPCs already have final character meshes.

See:
- `ASSET_LIBRARY_INDEX.json`: 93 manifest entries linked to their files, previews and technical reports.
- `LEGACY_ASSET_INDEX.json`: 64 additional legacy file records with stable LEGACY IDs and direct GitHub links; Git blob SHA-1 values are explicitly not SHA-256.
- `ASSET_GAP_BACKLOG.json`: missing/placeholder/improvement needs with stable GAP IDs.
- `PROVIDER_REGISTRY.json`: providers, official links, current free tiers and safety guards.
- `ASSET_CONVENTIONS.md`: taxonomy, stable ID formats, naming, mobile budgets and lifecycle states — where every class, NPC, enemy, boss, weapon, kit, material and VFX belongs.
- `PR19_RECONCILIATION.md`: map of what was migrated from PR #19 and what was superseded (single factory, single catalogue).
- `../DOCUMENTATION/PRODUCTION_STATUS.md`: original factory report; update it because its branch/PR wording is stale relative to the current main.
- `../../firebase/`: deny-by-default Firestore rules and optional-Firebase guide (Spark quotas, data model, NOT CONFIGURED status).

## 2. Source-of-truth hierarchy

1. Project owner decisions.
2. Current official repo state and merged code.
3. Current GDD, world bible and art direction.
4. `AGENTS.md` and Production Kit.
5. This automation layer.

Do not infer that a file is final just because it exists. Keep the following gates separate:

| Gate | Meaning |
|---|---|
| `CATALOGED` | Stable ID and metadata exist |
| `LICENSE_VERIFIED` | Exact source + license are recorded |
| `TECH_VALIDATED` | Technical checks pass |
| `VISUAL_REVIEW_PENDING` | Human still needs to inspect the preview |
| `VISUAL_APPROVED` | Owner approved the visual result |
| `GODOT_IMPORT_PASS` | Imported into Godot without critical errors |
| `SCENE_INTEGRATION_PASS` | Placed in the intended scene and visually checked |
| `ANDROID_DEVICE_PASS` | Checked on the target mobile device/profile |

No automation may promote an asset to `VISUAL_APPROVED` or `ANDROID_DEVICE_PASS` without evidence.

## 3. Canonical asset layout

Use existing folders and do not move the current 93 assets:

```text
assets/
  characters/
    player/<class_id>/
    npcs/<region_id>/<npc_id>/
  enemies/
    common/<enemy_id>/
    bosses/<boss_id>/
  items/
    weapons/<class_id>/
    armor/<slot>/<class_id>/
    accessories/
    materials/
  models/
    architecture/
    buildings/
    furniture/
    objects/
    rocks/
    urban/
    vegetation/
  environment/
    textures/<material_family>/
    regions/<region_id>/
    dungeons/<dungeon_id>/
  materials/
  animations/
    humanoid/
    quadruped/
    flying/
    spectral/
    amorphous/
    boss/
  effects/
    combat/
    magic/
    environment/
  ui/
ART_DEPARTMENT/
  CLOUD_AUTOMATION/
  AI_ASSET_FACTORY/
  PREVIEWS/
  DOCUMENTATION/
```

Rules:
- English folder/file names, `snake_case`; stable IDs are immutable once published.
- One canonical file location; do not duplicate the same binary across folders.
- GLB/glTF 2.0 preferred for Godot 4. FBX may be retained as source input only when conversion is justified.
- Model units: metres; +Y up; origin at base/feet for props/characters; character forward direction must be documented and consistent.
- Include textures in GLB or next to the GLB with stable names. PBR maps are named `*_base_color`, `*_normal`, `*_roughness`, `*_metallic`, `*_ao` (height only if justified).
- Every asset needs a preview image, source/license, SHA-256, profile, triangle count, dimensions, pivots, sockets, collision plan, LOD plan, validation report and relationships to scene/region/class/enemy.
- Do not generate Godot `.import` files or UIDs manually. Let Godot create them during import.

## 4. Library index and GAP backlog

`ASSET_LIBRARY_INDEX.json` is a navigation/search index, not a second source of truth. Regenerate it from the manifest and asset tree using:

```bash
python3 scripts/ci/build_asset_library_index.py --repo Lean031110/RPG-LBA --ref agent/asset-cloud-automation
python3 scripts/ci/build_asset_library_index.py --repo Lean031110/RPG-LBA --ref agent/asset-cloud-automation --check
```

The checked-in index is now schema **2.0.0** and CI enforces it strictly
(`.github/workflows/asset-library-index.yml`): every PR touching `assets/**`,
the factory manifest or this automation layer must also commit the regenerated
index, otherwise the run fails. The comparison ignores volatile provenance
metadata (`source_ref`, `source_commit`, the ref inside blob URLs) so a
content-identical index never looks stale after a ref change.

The generated rows must expose:
- stable `asset_id` (or `gap_id` for missing content);
- display name and canonical category;
- all files, GitHub URLs and SHA-256 hashes;
- creator/source URL/license and license-review status;
- preview and validation-report links;
- technical state, human-review state, Godot import state, scene state and Android state.

GAP IDs begin with `GAP_` and must never be reused as produced asset IDs. When a gap is filled, keep its history and connect it to the permanent asset ID; do not delete the gap silently.

## 5. Cloud architecture (internet-only baseline)

```text
GitHub schedule / manual dispatch / PR event
                 |
                 v
      GitHub Actions (public runner)
       | catalogue + gap + license scan
       | Blender background / Python factory
       | 3D Valley / Poly Haven / ambientCG
       | GLB/PBR limits + previews + reports
       v
     agent/asset-cloud-<batch> branch
                 |
         asset PR opened/updated
                 |
           Telegram alert
                 |
       Owner visual review in GitHub
                 |
       merge only after explicit approval
```

GitHub-hosted standard runners on public repos currently provide 4 vCPU, 16 GB RAM and 14 GB SSD with no runner-minute charge, but no hosted GPU. Blender can run headless on CPU to build/process models, export GLB, render small previews and validate. It cannot magically provide a free cloud GPU for large AI inference.

AI generation is a separate, quota-limited lane:
1. Query the provider's live model/price/quota endpoint.
2. Run only models explicitly marked free and zero-credit for that exact operation.
3. Persist an idempotency key/job ID/checkpoint before retrying.
4. Stop at quota/rate limit; record `QUOTA_EXHAUSTED`; resume after a real provider reset.
5. Do not create extra accounts or use account rotation to evade quotas.

## 6. Preferred providers

The live source and limits are in `PROVIDER_REGISTRY.json` (27 providers, schema 1.1.0, each with classification/quota/license_policy/cost_policy/limitations/notes/last_verified). Prioritize:
1. **GitHub Actions + Blender headless** for reliable CPU production, validation and preview generation.
2. **3D Valley REST API/MCP** for searching the CC0 library and limited AI model/texturing/animation runs. Its API has separate paid-credit tools and daily free models. Query `GET /tools` and `GET /account` before generation; refuse anything whose exact price is not zero; set `max_credits=0`; use idempotency keys.
3. **Poly Haven API** and **ambientCG API v3** for CC0 textures, HDRIs and models; record exact asset IDs/source URLs and hashes.
4. **Kenney / Quaternius / KayKit** as verified per-pack source libraries. Check each package's actual license.
5. **Hugging Face ZeroGPU** only for small experiments: free accounts currently have 5 GPU minutes/day and queues/availability are shared.
6. **Kaggle / Colab** as resumable notebook fallbacks, never as guaranteed 24/7 workers.
7. **JANCTION Render / SheepIt** optional for rendering only; neither is a dependable asset-generation core.

Never use a free trial or a provider that needs a card, paid credits, or billing activation as a pipeline dependency.

## 7. GitHub Actions safety

The repository is public. Standard hosted runner usage is currently free and unlimited for public repositories, but artifact retention is temporary and never the long-term storage mechanism.

- Keep all new work on `agent/*` or `feature/*` branches.
- `asset-factory.yml` now carries a first-step branch guard: it hard-fails if dispatched to `main`, `release*` or protected refs, before any checkout or write. `asset-publication.yml` keeps its job-level `if: github.ref_name != 'main'`.
- Scheduled execution goes through `asset-factory-scheduler.yml`, a dispatch-only safe dispatcher that validates the target ref against `agent/*|feature/*` (rejecting `main`/`release*`/empty) before calling `gh workflow run`. Its cron stays commented out until a full manual end-to-end pass (dispatcher → factory → validation → publication → PR) is approved by the owner; when enabled it always targets `ASSET_WORK_BRANCH`, never `main`.
- Actions permissions: least privilege. Prefer the automatic short-lived `GITHUB_TOKEN`; only grant `contents: write` to the asset branch publisher and `pull-requests: write` to PR creation.
- Avoid recursive workflow loops; add `[skip ci]` only where the commit genuinely should not retrigger the workflow.
- Never merge a PR automatically.
- Use concurrency groups, max batch sizes, job timeouts, resumable queue state and deterministic seeds.
- Keep large model weights and datasets out of Git. Check repository size and LFS costs before introducing Git LFS or external binary storage.

## 8. Telegram notifications

A notification workflow should send plain text only:
- asset PR opened/updated -> ask owner to review preview/catalogue;
- asset factory completed -> report counts and run link;
- validation/factory failed -> report conclusion and logs link;
- provider quota exhausted -> report provider and reset/unknown state.

Create a bot with `@BotFather` using `/newbot`; then send the bot `/start`. Determine the private `chat_id` from `getUpdates` or from a controlled group. Store both values as GitHub Actions secrets:
- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_CHAT_ID`

Never put the token in workflow JSON, source code, a commit, an issue, a public log, or a Telegram message. The bot is notification-only initially; approvals happen in GitHub PR review until a secure, signed callback flow is separately reviewed.

## 9. Firebase: optional, not a requirement

Do not make Firebase a dependency of asset production. GitHub manifest + PR + Actions are the durable baseline.

If a dashboard is later needed, Firebase Spark can hold small status/metadata documents in Firestore within its published free quotas. Do not store GLB/texture binaries in Firestore. Cloud Storage for Firebase now requires the Blaze plan even though some no-cost usage exists; Cloud Functions also require Blaze. Because the owner requires zero billing, the MVP must not enable these services. A Firestore dashboard can be considered only after reviewing the current pricing, security rules and project region, and without a billing upgrade.

## 10. Credentials: where they go

Use GitHub repository Settings → Secrets and variables → Actions → New repository secret. Do not create a committed `.env` with live values.

| Secret | Required? | Purpose |
|---|---:|---|
| `TELEGRAM_BOT_TOKEN` | Yes, for Telegram alerts | Bot token from @BotFather |
| `TELEGRAM_CHAT_ID` | Yes, for Telegram alerts | Private chat/group ID |
| `3DVALLEY_API_KEY` | Optional, recommended for library/API quota | Free API key from 3D Valley account |
| `HF_TOKEN` | Optional | Authenticated/private Hugging Face endpoints only |
| `KAGGLE_USERNAME` + `KAGGLE_KEY` | Optional | Kaggle API/notebook experiments |
| `JANCTION_API_KEY` | Not required | Add only if a free zero-cost key is issued and live terms are acceptable |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Not required | Only for future Firestore dashboard; do not use Storage/Functions without billing approval |
| `N8N_ENCRYPTION_KEY` | Not an asset-generation secret | Store privately in a password manager/secure vault; never commit |
| `N8N_API_KEY` | Not assumed | The Cloud trial may not expose the public API; do not build the MVP around it |

The repo's GitHub Actions `GITHUB_TOKEN` is provided automatically; no personal token is needed for normal actions. Set workflow-level permissions explicitly.

## 11. Asset approval workflow

1. Agent reads the GDD, art direction, world bible, current catalogue and GAP backlog.
2. It proposes one batch and lists all assets it will create/download.
3. License scanner rejects unknown/restrictive licenses before download.
4. Generation/import pipeline writes stable metadata and hashes.
5. Blender/Godot validation produces reports and preview images.
6. A pull request links every asset, preview, report and the GAP IDs it resolves.
7. Telegram tells the owner to review.
8. Owner approves/requests changes through GitHub.
9. Only after accepted PR merge can the asset be considered published in main. Visual/Android approval stays distinct.

## 12. Unresolved canon decision

The owner-facing backlog flags a narrative-scope discrepancy: the broad project vision says five main bosses, while the current world bible names six boss encounters (four regional bosses, Aurelio Varela and the final Ash King). Keep all six entries visible; do not silently delete or merge one. The world bible names seven major locations, which can provisionally be interpreted as two hubs (Valdeluz and La Habana de las Campanas) plus five exterior regions; verify this before authoring region kits.

## 13. Definition of Done

An asset batch is not complete until:
- stable IDs unique and paths valid;
- exact source/license and SHA-256 present;
- no duplicate files or accidental overwrite;
- mobile triangle/texture/material budgets checked;
- rig, animations, sockets, pivot and collisions documented where applicable;
- every asset has a preview and a machine-readable validation report;
- Godot 4.7.2 import is tested without critical errors;
- scene and Android status is stated honestly;
- human visual review is complete before visual approval;
- PR is linked and no changes were pushed directly to main.

Report PASS / FAIL / SKIPPED / NOT TESTED only with evidence. 


## 14. Correcciones de proveedores verificadas (15 November 2026)

**3D Valley:** automatizar únicamente búsqueda/descarga de recursos de su biblioteca CC0. La API oficial aclara que cada herramienta API (generar, editar, texturizar, etc.) consume créditos; 1 crédito equivale a USD 0.01. `max_credits=0` evita gasto, pero no convierte una operación de pago en gratuita. No automatizar generación por API con presupuesto cero. La interfaz web puede ofrecer operaciones gratuitas limitadas, pero se trata como uso manual, variable y no garantizado. Referencia: https://3dvalley.com/docs/api

**Meshy Free:** manual-only, 100 créditos/mes y hasta 10 descargas por mes de modelos Meshy 6 Lite sin textura. No ofrece API en el plan gratuito. Los outputs Free usan CC BY 4.0, permiten uso comercial con atribución a Meshy. No presupuestar modelos texturizados como descarga gratuita. Referencia: https://help.meshy.ai/en/articles/15696428-what-is-included-on-the-free-plan

**Smithsonian Open Access:** fuente opcional para referencias y objetos culturales; la API requiere una clave gratuita de api.data.gov. Solo descargar medios cuando el registro individual esté marcado CC0; algunos elementos ofrecen metadatos sin archivo descargable. Referencias: https://www.si.edu/openaccess/devtools y https://www.si.edu/openaccess/faq

**Tripo Free:** no aprobado por defecto como proveedor de producción. Aunque el plan publica créditos gratuitos, la documentación consultada indica que la IP del output pertenece a Tripo y el uso comercial gratuito requiere atribución. No integrar resultados hasta revisar términos completos y aprobar la procedencia/licencia en el manifiesto.

**n8n:** no usar el Source Control/Environments integrado como solución gratuita: la guía oficial lo limita a Business y Enterprise. El Cloud Trial tampoco tiene API pública. El camino gratuito/portable es versionar workflows JSON sanitizados en GitHub, exportar explícitamente tablas/datos por separado y guardar credenciales/clave de cifrado/DB en backup privado cifrado. Referencias: https://docs.n8n.io/administer/use-source-control-and-environments/tutorial-create-environments-with-source-control/ y https://support.n8n.io/article/can-i-have-api-access-while-i-am-on-a-trial

No se considerará conectada una integración hasta que haya prueba real. La documentación de proveedores no sustituye la configuración de secrets ni las pruebas de llamada.


## 15. First GPU generation experiment — TripoSR on Kaggle

The preferred first automated GPU experiment is the open-source **TripoSR** model (not the Tripo AI website). Its upstream repository states that code and pretrained weights are MIT-licensed and that a single image requires approximately 6 GB VRAM: https://github.com/VAST-AI-Research/TripoSR

Kaggle's official CLI supports remote notebook submission with `kaggle kernels push -p <FOLDER_PATH>` and accelerator selection such as `--accelerator NvidiaTeslaT4`: https://github.com/Kaggle/kaggle-cli/blob/main/docs/kernels.md

Implementation constraints:
- A GitHub Actions job dispatches a versioned, private Kaggle kernel only when a live quota/accelerator check indicates it can run.
- The Kaggle notebook downloads a pinned TripoSR revision and pinned weights; it processes one bounded batch of original/licensed images and writes compact checkpoints.
- The result is uploaded back through a controlled artifact handoff; GitHub Actions then runs Blender headless for mesh cleanup/decimation/scale/pivot/export GLB, validates SHA-256 and creates a candidate PR.
- The job must be idempotent and resumable. Never rerun the same expensive generation if a completed job ID/checkpoint exists.
- Quota unavailable => `DEFERRED_QUOTA`, not failure loops. Never use multiple accounts or paid accelerators.
- TripoSR is for rough single-view reconstruction of static objects; it does not replace character modeling, rigging, retargeting, animation, art direction or human review.

Stable Fast 3D is an optional alternative only after confirming the Community License commercial-revenue threshold (USD 1M/year) and GPU compatibility: https://huggingface.co/stabilityai/stable-fast-3d
