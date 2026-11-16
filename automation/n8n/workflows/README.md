# Workflow template library

Place reviewed n8n export JSON templates here.

Each template must have a companion document including:
- workflow purpose and trigger;
- target n8n version and node/type versions;
- expected input/output payloads;
- required credential names (logical names, no secret values);
- side effects and rate limits;
- idempotency/deduplication design;
- disabled/inactive default state;
- valid, invalid and duplicate test results;
- whether it was tested by importing/running a disposable instance.

No live exports or credentials are stored here yet. The connected n8n instance could not be inspected during this setup, so no claim is made that its current workflows were exported.
