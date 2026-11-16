# Private n8n backup storage (instructions only)

This directory must remain free of backup data. Never commit a real backup, .n8n folder, SQLite file, database dump, credential export, encryption key or tokens.

Store full backups in a user-controlled encrypted location (password manager / encrypted archive storage). Use the public Git repo only for sanitized portable workflow templates and restore instructions.

Before each planned instance change:
1. export sanitized workflows;
2. export encrypted credentials to a private archive, never Git;
3. preserve the same encryption key privately;
4. back up .n8n + external DB/files if self-hosted;
5. verify a restore in a disposable instance.
