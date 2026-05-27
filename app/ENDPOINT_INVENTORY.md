# OMI Mobile — Endpoint Inventory

**Date:** 2026-05-24
**Branch:** `feat/mobile-endpoint-pointing`
**Generator:** Static grep over `app/lib/backend/http/api/*.dart` + `app/lib/services/auth_service.dart` + `app/lib/services/sockets/*.dart`.
**Total unique normalised routes:** 162 REST + 1 WS (`/v4/listen`) + 1 WS (`/v1/agent/ws` derived).

## Conventions

- All REST URLs are built as `${Env.apiBaseUrl}<path>` (`apiBaseUrl` always ends with `/`).
- Auth header: `Authorization: Bearer <firebase-id-token>` for everything except `/v1/auth/authorize` (browser-redirect) and `/v1/auth/token` (code exchange). See `lib/backend/http/shared.dart:42-86`.
- Path variables shown as `{id}` (originally Dart `${var}` interpolations).
- Method column inferred from call-site (`http.get` / `http.post` / `http.put` / `http.delete`). When unclear, marked `?`.

---

## 1. Boot-critical (App will NOT show home screen without these)

These are called in `main.dart` boot flow, `AuthService.restoreOnboardingState()`, the first frame of `HomePageWrapper`, or as immediate `WidgetsBinding.instance.addPostFrameCallback` work.

| Method | Path | Purpose | Min stub response |
|---|---|---|---|
| GET | `v1/users/onboarding` | restore onboarding state on cold start | `{"completed": false}` or `{"completed": true}` |
| PUT | `v1/users/onboarding` | persist onboarding completion | `200 {}` |
| GET | `v1/users/profile` | minimal user profile | `{"user_id": "...", "email": "...", "name": "..."}` |
| GET | `v1/users/private-cloud-sync` | private-cloud-sync flag (used in many init paths) | `{"enabled": false}` |
| POST | `v1/users/store-recording-permission` | record consent ack | `200 {}` |
| POST | `v1/users/fcm-token` | FCM token registration (post-login) | `200 {}` |
| GET | `v1/fair-use/status` | per-action limit gate | `{"unlimited": true}` |
| GET | `v1/users/me/subscription` | paywall gate | `{"tier": "free", "status": "active"}` |
| GET | `v1/announcements/pending` | announcement banner | `[]` |

## 2. Auth (only if `USE_WEB_AUTH=true`)

Only used when the dev-env opted into web-auth. Set `USE_WEB_AUTH=false` in `.dev.env` to bypass these and use Firebase mobile SDK directly. See `AUTH_STRATEGY.md`.

| Method | Path | Purpose |
|---|---|---|
| GET | `v1/auth/authorize` | OAuth start (browser-opens this) — query params: `provider`, `redirect_uri` |
| POST | `v1/auth/token` | code → custom-token exchange |

## 3. Home tab / Conversations

Called lazily — empty arrays are fine for first-paint.

| Method | Path | Purpose | Min stub |
|---|---|---|---|
| GET | `v1/conversations/` | conversation list (paginated; `?offset=&limit=`) | `[]` |
| GET | `v1/conversations/{id}` | conversation detail | 404 OK for empty stub |
| GET | `v1/conversations/{id}/transcripts` | transcript segments | `[]` |
| GET | `v1/conversations/{id}/action-items` | per-conversation action items | `[]` |
| POST | `v1/conversations/search` | search | `[]` |
| POST | `v1/conversations/merge` | merge | n/a |
| PUT | `v1/conversations/{id}/title` | rename | `200 {}` |
| PUT | `v1/conversations/{id}/starred` | star | `200 {}` |
| PUT | `v1/conversations/{id}/visibility` | visibility | `200 {}` |
| POST | `v1/conversations/{id}/folder` | move to folder | `200 {}` |
| POST | `v1/conversations/{id}/summary` | regenerate summary | `200 {}` |
| POST | `v1/conversations/{id}/reprocess` | reprocess | n/a |
| POST | `v1/conversations/{id}/segments/text` | manual transcript text | `200 {}` |
| POST | `v1/conversations/{id}/segments/assign-bulk` | speaker bulk-assign | `200 {}` |
| POST | `v1/conversations/{id}/test-prompt` | dev prompt | n/a |
| GET | `v1/conversations/{id}/suggested-apps` | suggested apps | `[]` |
| GET | `v1/folders` | folder list | `[]` |
| POST | `v1/folders` | create | `200 {"id": "..."}` |
| PUT | `v1/folders/{id}` | rename | `200 {}` |
| DELETE | `v1/folders/{id}` | delete | `200 {}` |
| POST | `v1/folders/reorder` | reorder | `200 {}` |
| POST | `v1/folders/{id}/conversations/bulk-move` | bulk-move | `200 {}` |

## 4. Memories tab

| Method | Path | Purpose | Min stub |
|---|---|---|---|
| GET | `v3/memories` | memory list | `[]` |
| GET | `v3/memories/{id}` | memory detail | 404 |
| PUT | `v3/memories/{id}/visibility` | visibility | `200 {}` |
| POST | `v1/users/analytics/memory_summary` | analytics ping | `200 {}` |

## 5. Apps / MCP

| Method | Path | Purpose | Min stub |
|---|---|---|---|
| GET | `v1/apps/enabled` | enabled apps | `[]` |
| GET | `v1/apps` | catalogue (with filter query) | `[]` |
| GET | `v1/apps/popular` | popular apps | `[]` |
| GET | `v2/apps` | v2 list | `[]` |
| POST | `v2/apps/search` | search | `[]` |
| GET | `v2/apps/capability/{cap}/grouped` | grouped by capability | `[]` |
| GET | `v1/app-categories` | categories | `[]` |
| GET | `v1/app-capabilities` | capabilities | `[]` |
| GET | `v1/apps/{appId}` | app detail | 404 |
| POST | `v1/apps/enable` | enable | `200 {}` |
| POST | `v1/apps/disable` | disable | `200 {}` |
| GET | `v1/apps/{id}/review` | get review | 404 |
| POST | `v1/apps/{id}/review` | submit review | `200 {}` |
| POST | `v1/apps/{id}/review/reply` | reply to review | `200 {}` |
| POST | `v1/apps/{id}/refresh-manifest` | refresh manifest | `200 {}` |
| PUT | `v1/apps/{id}/change-visibility` | visibility | `200 {}` |
| GET | `v1/apps/{id}/keys` | API keys | `[]` |
| POST | `v1/apps/{id}/keys` | create key | `200 {}` |
| DELETE | `v1/apps/{id}/keys/{keyId}` | delete key | `200 {}` |
| GET | `v1/apps/{id}/subscription` | sub status | `{"active": false}` |
| POST | `v1/apps/migrate-owner` | migrate owner | `200 {}` |
| GET | `v1/apps/mcp` | MCP integrations | `[]` |
| POST | `v1/app/generate` | generator (LLM) | n/a for v0 |
| POST | `v1/app/generate-description` | LLM | n/a |
| POST | `v1/app/generate-description-emoji` | LLM | n/a |
| POST | `v1/app/generate-icon` | LLM | n/a |
| POST | `v1/app/generate-prompts` | LLM | n/a |
| GET | `v1/app/plans` | plans | `[]` |
| GET | `v1/app/thumbnails` | thumbnails | `[]` |
| GET | `v1/mcp` | MCP servers | `[]` |

## 6. Action items / Goals

| Method | Path | Min stub |
|---|---|---|
| GET | `v1/action-items` | `[]` |
| POST | `v1/action-items` | `200 {}` |
| POST | `v1/action-items/batch` | `200 {}` |
| POST | `v1/action-items/batch-delete` | `200 {}` |
| POST | `v1/action-items/accept` | `200 {}` |
| POST | `v1/action-items/pending-sync` | `200 {}` |
| POST | `v1/action-items/sync-batch` | `200 {}` |
| POST | `v1/action-items/share` | `200 {}` |
| GET | `v1/action-items/shared/{id}` | 404 |
| GET / PUT / DELETE | `v1/action-items/{id}` | `200 {}` |
| GET | `v1/goals` | `[]` |
| GET | `v1/goals/all` | `[]` |
| POST | `v1/goals` | `200 {}` |
| POST | `v1/goals/advice` | n/a (LLM) |
| POST | `v1/goals/suggest` | `[]` |
| GET / PUT / DELETE | `v1/goals/{id}` | `200 {}` |
| GET | `v1/goals/{id}/progress` | `{"percent": 0}` |

## 7. Messages / chat / agent

| Method | Path | Notes |
|---|---|---|
| GET | `v2/messages` | message list |
| POST | `v2/messages` | send message |
| POST | `v2/messages/{id}/report` | report |
| GET | `v2/initial-message` | initial greeting |
| WS | `wss://agent.<host>/v1/agent/ws` | agent streaming. Derived from apiBaseUrl by replacing `api.` with `agent.` — see `Env.agentProxyWsUrl`. **Stub needs to host wss endpoint or app must accept fallback.** |
| POST | `v1/agent/keepalive` | keepalive |
| POST | `v1/agent/vm-ensure` | ensure vm |
| GET | `v1/agent/vm-status` | vm status |

## 8. Speech / TTS / Voice / Audio

| Method | Path | Notes |
|---|---|---|
| GET / POST / DELETE | `v3/speech-profile` | speech profile |
| POST | `v3/speech-profile/expand` | enroll |
| GET | `v4/speech-profile` | v4 profile |
| POST | `v3/upload-audio` | upload |
| POST | `v2/tts/synthesize` | TTS |
| POST | `v2/voice-message/transcribe` | voice msg transcribe |
| GET / POST | `v2/voice-messages` | voice messages |
| POST | `v2/sync-local-files` | sync local audio |
| GET | `v2/sync-local-files/{id}` | status |
| GET | `v2/files` | files |
| GET | `v1/sync/audio/{id}/urls` | presigned URLs |
| POST | `v1/sync/audio/{id}/precache` | precache |
| GET | `v1/sync/audio/{id}/{name}` | download |
| WS | `wss://<host>/v4/listen` | **streaming STT** — `transcription_service.dart:125`. Query params drive deepgram-style protocol. Critical for recording flow; out of scope for v0 stub. |

## 9. Wrapped 2025

| Method | Path |
|---|---|
| GET | `v1/wrapped/2025` |
| POST | `v1/wrapped/2025/generate` |

## 10. Integrations / Tasks / Phone

| Method | Path |
|---|---|
| GET / DELETE | `v1/integrations/{id}` |
| GET | `v1/integrations/{id}/oauth-url` |
| POST | `v1/integrations/apple-health/sync` |
| GET / POST / PUT / DELETE | `v1/task-integrations` + `v1/task-integrations/{id}` |
| GET | `v1/task-integrations/default` |
| GET | `v1/task-integrations/{id}/oauth-url` |
| GET | `v1/task-integrations/{id}/tasks` |
| GET | `v1/task-integrations/asana/workspaces` |
| GET | `v1/task-integrations/asana/projects/{wsId}` |
| GET | `v1/task-integrations/clickup/teams` |
| GET | `v1/task-integrations/clickup/spaces/{teamId}` |
| GET | `v1/task-integrations/clickup/lists/{spaceId}` |
| GET / POST | `v1/phone/numbers` + `/verify` + `/verify/check` + `/{id}` + `/token` |
| GET | `v1/import/jobs` |
| POST | `v1/import/limitless` |
| GET | `v1/import/limitless/conversations` |

## 11. Payments / Stripe

| Method | Path |
|---|---|
| POST | `v1/payments/checkout-session` |
| POST | `v1/payments/customer-portal` |
| GET | `v1/payments/available-plans` |
| POST | `v1/payments/upgrade-subscription` |
| GET / DELETE | `v1/payments/subscription` |
| GET | `v1/payment-methods/default` |
| GET | `v1/payment-methods/status` |
| GET | `v1/paypal/payment-details` |
| GET / POST | `v1/stripe/connect-accounts` |
| GET | `v1/stripe/onboarded` |
| GET | `v1/stripe/supported-countries` |

## 12. Misc users / settings

| Method | Path |
|---|---|
| GET / PUT | `v1/users/preferences/app` |
| GET / PUT | `v1/users/training-data-opt-in` |
| GET / PUT | `v1/users/transcription-preferences` |
| GET / PUT | `v1/users/mentor-notification-settings` |
| GET / POST | `v1/users/daily-summaries` + `/{date}` + `/daily-summary-settings` + `/test` |
| GET | `v1/users/me/usage` |
| GET | `v1/users/me/subscription` |
| GET / POST / DELETE | `v1/users/people` + `/{id}` + `/{id}/name` + `/{id}/speech-samples/{sampleId}` |
| GET | `v1/users/export` |
| DELETE | `v1/users/delete-account` |
| POST | `v1/users/analytics/chat_message` |
| POST | `v1/users/migration/batch-requests` |
| GET | `v1/users/migration/requests` |
| POST | `v1/users/migration/requests/data-protection-level/finalize` |
| GET / POST | `v1/users/geolocation` |
| GET / POST / DELETE | `v1/users/developer/webhook/{type}` + `/enable` + `/disable` |
| GET | `v1/users/developer/webhooks/status` |

## 13. Announcements / Knowledge Graph / Firmware / Dev

| Method | Path |
|---|---|
| GET | `v1/announcements/pending` |
| GET | `v1/announcements/changelogs` |
| POST | `v1/announcements/{id}/dismiss` |
| GET | `v1/knowledge-graph` |
| GET | `v2/firmware/latest` |
| GET | `v2/firmware/stable` |
| GET | `v1/dev` |

---

## Source of truth

```
app/lib/backend/http/api/        # all REST clients
app/lib/services/auth_service.dart   # auth endpoints
app/lib/services/sockets/transcription_service.dart  # WS /v4/listen
app/lib/env/env.dart             # apiBaseUrl + agentProxyWsUrl derivation
app/lib/backend/http/shared.dart # Bearer-token injection
```

Re-generate this inventory:
```bash
grep -rh "Env.apiBaseUrl" app/lib/backend/http/api/ \
  | grep -oE "v[0-9]+/[a-zA-Z0-9_/?=&{}.\$\-]+" \
  | sed 's/[?].*//' \
  | sed -E 's/\$\{[^}]+\}/{var}/g; s/\$[a-zA-Z_]+/{var}/g' \
  | sort -u
```
