# Teams Transcript Requirements Function App

Production-grade Azure Functions (Python v2 programming model) app that:

1. Receives Microsoft Graph change notifications for Teams transcripts.
2. Fetches transcript content from Graph.
3. Converts WebVTT to speaker-attributed text.
4. Sends transcript + existing requirements to Azure OpenAI for requirement extraction.
5. Appends results to `requirements_latest.md` and writes a versioned copy in Azure Blob Storage.

## Architecture

- `function_app.py`
  - `GET /api/webhook`: Graph validation handshake (`validationToken` echoed exactly as received)
  - `POST /api/webhook`: accepts Graph notifications or direct test payloads and enqueues work
  - `QueueTrigger`: executes heavy pipeline work
  - `TimerTrigger`: renews or creates Graph subscriptions
- `src/pipeline/graph_client.py`: MSAL client credentials auth, Graph API calls, resource parsing, VTT parsing
- `src/pipeline/openai_merge.py`: Azure OpenAI merge/summarization call
- `src/pipeline/blob_store.py`: requirements read/write with versioned snapshots
- `src/pipeline/routing.py`: `MEETING_ROUTING` resolver
- `src/pipeline/subscription.py`: Graph subscription create/renew
- `src/pipeline/pipeline.py`: orchestration

## Environment Variables

Copy `.env.example` and populate values from your Azure environment. Do not hardcode secrets.

## Local Development

1. Install dependencies:
   ```bash
   pip install -e .[dev]
   ```
2. Copy `local.settings.json.example` to `local.settings.json` and fill values.
3. Run Azurite if you want integration tests:
   ```bash
   docker run --rm -p 10000:10000 -p 10001:10001 mcr.microsoft.com/azure-storage/azurite
   ```
4. Run tests/lint:
   ```bash
   ruff check .
   pytest
   ```

## Graph Payloads

### Validation

`GET /api/webhook?validationToken=...` returns token exactly (no URL-decoding).

### Notification shape

```json
{
  "value": [
    {
      "clientState": "...",
      "resource": "communications/onlineMeetings('...')/transcripts('...')"
    }
  ]
}
```

### Direct invocation shape

```json
{
  "meeting_id": "...",
  "transcript_id": "...",
  "project": "...",
  "workstream": "...",
  "customer": "...",
  "meeting_name": "..."
}
```

## Infra + Deploy

- `infra/main.bicep`: Function App + Storage + diagnostics
- `infra/deploy.sh`: `az` CLI deployment wrapper
- `.github/workflows/ci.yml`: PR lint + tests
- `.github/workflows/deploy.yml`: publish on `main` via `func azure functionapp publish`
