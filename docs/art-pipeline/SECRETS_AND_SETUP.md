# Secrets and API setup — RPG LBA Asset Factory

Never paste real tokens into ChatGPT, Z.ai prompts, GitHub issues, source files or workflow JSON. Configure them directly in the target secret manager.

## Where each secret belongs

| Secret | Where to store | Used by |
|---|---|---|
| GITHUB_TOKEN | Automatically provided by GitHub Actions; do not create manually | Workflows in this repository |
| Optional GitHub fine-grained PAT | GitHub → repository Settings → Secrets and variables → Actions → New repository secret | Only if an external service must call GitHub API; prefer GitHub App or GITHUB_TOKEN |
| TELEGRAM_BOT_TOKEN | n8n Credentials (Telegram) and/or GitHub Actions repository secret | Telegram notification workflow |
| TELEGRAM_CHAT_ID | n8n workflow configuration/credential or Actions secret; treat as private identifier | Destination for Telegram messages |
| HF_TOKEN | n8n Credentials or Actions secret only if gated/private HF resource is required | Hugging Face |
| KAGGLE_USERNAME / KAGGLE_KEY | Actions secrets or n8n Credentials | Kaggle API automation |
| SMITHSONIAN_API_KEY | Actions secret or n8n Credentials | Smithsonian API |
| FIREBASE_SERVICE_ACCOUNT_JSON | Secret manager only; Actions secret for CI backend, or n8n credential | Server-side Firebase Admin SDK |
| FIREBASE_PROJECT_ID | Non-secret repository variable or workflow variable | Firebase project selector |
| N8N_ENCRYPTION_KEY | Secret manager and separate encrypted recovery copy; self-hosted n8n only | Decrypting stored n8n credentials after restore |
| JANCTION_API_KEY | n8n/Actions secret only if current beta issues one | Optional experimental renderer |

Poly Haven and ambientCG public API endpoints do not require API keys. Do not create unnecessary tokens.

## How to obtain each key

### Telegram
1. Open Telegram and start a chat with @BotFather.
2. Send /newbot and follow the prompts.
3. Copy the bot token once; store it directly in n8n Credentials or GitHub Actions Secrets.
4. Open the new bot and send /start.
5. Obtain your chat ID using a secure getUpdates test or a trusted bot-management workflow.
6. Never commit the token or include it in screenshots/prompts.

Official Bot API: https://core.telegram.org/bots/api

### Hugging Face
1. Create/sign in: https://huggingface.co/
2. Open https://huggingface.co/settings/tokens.
3. Create a fine-grained token with only the permissions needed for the model/Space.
4. Public Spaces may work without a token; do not create one unless required.

### Kaggle
1. Sign in: https://www.kaggle.com/
2. Open https://www.kaggle.com/settings.
3. In API, create/download a token.
4. Store username and key as separate secrets; never upload kaggle.json into the repo.
5. Check GPU quota and availability manually before dispatching expensive jobs.

### Smithsonian
1. Request an API key at https://api.data.gov/signup/.
2. Use the key only for metadata lookup; download only objects marked CC0.
3. Store it as SMITHSONIAN_API_KEY.

### Firebase
1. Open https://console.firebase.google.com/ and create a project for RPG LBA Asset Factory.
2. Select Spark (no-cost) and do not enable billing/Blaze without owner approval.
3. Add a Web app only if a dashboard is needed.
4. Create Cloud Firestore in the appropriate region; use the repository's deny-by-default rules as a starting point.
5. Enable only the needed sign-in provider (prefer one admin account; avoid phone/SMS).
6. Service-account private keys are backend-only. If needed, create under Project settings → Service accounts and store the JSON as FIREBASE_SERVICE_ACCOUNT_JSON in the secret manager. Never place it in frontend code.
7. Add App Check before exposing a public dashboard.
8. Monitor usage and do not rely on Firestore native backups under Spark; maintain JSON exports in GitHub.

Firebase console: https://console.firebase.google.com/
Spark/Blaze pricing: https://firebase.google.com/pricing

### GitHub fine-grained token (only if needed)
Prefer the automatic GITHUB_TOKEN inside Actions. If an external n8n instance must call GitHub:
1. Open GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens.
2. Select only RPG-LBA as repository access.
3. Grant only Contents (read/write) and Pull requests (read/write) if required; Actions (read/write) only when dispatching workflows is necessary; Metadata read is automatic.
4. Save the token directly as a GitHub Actions secret or n8n credential. Do not send it to an AI agent in plain text.

## n8n Cloud vs Community Edition
- In n8n Cloud, create credentials in the Credentials UI and assign them to imported nodes.
- Do not assume Cloud exposes shell environment variables or the public API on a trial plan.
- The current Cloud trial excludes the n8n public API; use the UI to export/import workflows unless the plan changes.
- In self-hosted Community Edition, configure N8N_ENCRYPTION_KEY in the deployment environment and back it up securely outside GitHub.
- The n8n encryption key is not a substitute for database backups.

## Owner setup checklist
- [ ] Telegram bot created; token saved in secret manager
- [ ] Telegram chat ID recorded securely
- [ ] HF token created only if gated models require it
- [ ] Kaggle API token created only if notebook automation is enabled
- [ ] Smithsonian API key created only if Smithsonian source is enabled
- [ ] Firebase Spark project created; billing remains disabled
- [ ] GitHub Actions secrets configured without committing values
- [ ] n8n credentials configured and test messages succeed
- [ ] n8n workflow export/import and restore tested
