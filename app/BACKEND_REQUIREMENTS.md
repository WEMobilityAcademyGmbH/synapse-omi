# Backend-Stub Requirements — For Sub-Agent E (FastAPI Server)

**Date:** 2026-05-24
**Consumer:** OMI Mobile App (`feat/mobile-endpoint-pointing` branch on our fork)
**Author of this doc:** Coordinator (mobile-side)
**Target deployment:** `http://localhost:8050` for sim-smoke; eventually `https://omi-dev.atwenture.de/`

This is the **minimum** the backend stub must answer for the iOS-Simulator OMI app to boot through onboarding, reach the home tab, and not crash. Everything else can 404 / 501 for v0.

---

## Global

- **Base URL** must end with `/` (the app concatenates `${Env.apiBaseUrl}<path>` where `<path>` has no leading `/`).
- **Auth header on every authenticated call:** `Authorization: Bearer <token>`. For Phase-1.1 (Option B2 in `AUTH_STRATEGY.md`), the stub trusts any token matching `^dev-mock-.*$`. Reject other tokens with `401`.
- **CORS:** App is iOS-simulator-native HTTP client, so CORS is irrelevant. But please set `Access-Control-Allow-Origin: *` anyway for future web-frontend cases.
- **Content-Type:** `application/json` on every response.
- **Trailing slashes:** match exactly what the client sends. The client mostly uses no trailing slash, except `v1/conversations/` which has one. Be permissive (FastAPI's `redirect_slashes=True` is fine).

---

## TIER 1 — Boot-critical (return one of these or app hangs)

**The app will not finish startup unless these answer with 2xx.** Implement these first.

| # | Method | Path | Response body | Notes |
|---|---|---|---|---|
| 1 | `GET`  | `/v1/users/onboarding` | `{"completed": true}` | Set `completed=true` so the app skips the onboarding screens entirely. (We'll re-enable onboarding when we want to test that flow.) |
| 2 | `PUT`  | `/v1/users/onboarding` | `{}` 200 | Accept any JSON body. |
| 3 | `GET`  | `/v1/users/profile` | `{"user_id": "dev-user-1", "email": "dev@atwenture.de", "name": "Dev User"}` | UID must match `Bearer dev-mock-<uid>` if you want strict; otherwise fixed dev user is fine. |
| 4 | `GET`  | `/v1/users/private-cloud-sync` | `{"enabled": false}` | |
| 5 | `POST` | `/v1/users/store-recording-permission` | `{}` 200 | Accept `?value=true|false` or JSON body. |
| 6 | `POST` | `/v1/users/fcm-token` | `{}` 200 | Accept FCM token in body, no-op. |
| 7 | `GET`  | `/v1/fair-use/status` | `{"unlimited": true}` | If absent, app blocks user actions. |
| 8 | `GET`  | `/v1/users/me/subscription` | `{"tier": "free", "status": "active", "renews_at": null}` | |
| 9 | `GET`  | `/v1/announcements/pending` | `[]` | Empty list = no banners. |

---

## TIER 2 — Home/Memories/Apps tab rendering (empty-state)

Without these, the app reaches home tab but each tab shows an error spinner. Empty arrays make them render the empty-state UI.

| Method | Path | Response | Notes |
|---|---|---|---|
| `GET` | `/v1/conversations/` | `[]` | Accepts `?offset=&limit=` query. |
| `GET` | `/v3/memories` | `[]` | |
| `GET` | `/v1/apps/enabled` | `[]` | |
| `GET` | `/v1/apps` | `[]` | Accepts filter query params. |
| `GET` | `/v1/apps/popular` | `[]` | |
| `GET` | `/v2/apps` | `[]` | |
| `GET` | `/v1/app-categories` | `[]` | |
| `GET` | `/v1/app-capabilities` | `[]` | |
| `GET` | `/v1/action-items` | `[]` | |
| `GET` | `/v1/goals` | `[]` | |
| `GET` | `/v1/goals/all` | `[]` | |
| `GET` | `/v1/folders` | `[]` | |
| `GET` | `/v2/messages` | `[]` | |
| `GET` | `/v2/initial-message` | `{"role":"assistant","text":"Hi from atwenture-stub. This is a smoke deployment."}` | Without this the chat tab is blank but doesn't crash. |
| `GET` | `/v1/knowledge-graph` | `{"nodes": [], "edges": []}` | |
| `GET` | `/v2/firmware/latest` | `{"version": "0.0.0", "url": null}` | |
| `GET` | `/v2/firmware/stable` | `{"version": "0.0.0", "url": null}` | |
| `GET` | `/v1/users/preferences/app` | `{}` | App-specific prefs blob. |
| `GET` | `/v1/users/training-data-opt-in` | `{"opted_in": false}` | |
| `GET` | `/v1/users/transcription-preferences` | `{"language": "en", "model": null}` | |
| `GET` | `/v1/users/mentor-notification-settings` | `{"enabled": false}` | |
| `GET` | `/v1/announcements/changelogs` | `[]` | |

---

## TIER 3 — Catch-all to avoid 500s

Add a **catch-all `404`** for any other `/v*` path that returns:
```json
{"detail": "Not implemented in dev stub", "path": "<path>"}
```
The mobile app handles 404s on most endpoints gracefully; what kills it is a 500 or a long timeout. Set timeouts low.

Specifically, **return 404 (not 500)** for:
- All `/v1/conversations/{id}/...` paths
- All `/v3/memories/{id}/...` paths
- All `/v1/apps/{appId}/...` paths
- All `/v1/goals/{id}/...` paths
- All `/v1/folders/{id}/...` paths
- All `/v1/action-items/{id}` paths

---

## TIER 4 — Endpoints NOT to implement (out of scope for v0)

| Path | Why skip |
|---|---|
| `wss://<host>/v4/listen` | Real-time STT, deepgram protocol. Recording flow is post-v0. |
| `wss://agent.<host>/v1/agent/ws` | Agent streaming. Chat-with-agent is post-v0. |
| `/v1/auth/authorize` + `/v1/auth/token` | Only needed if `USE_WEB_AUTH=true`. We set `USE_WEB_AUTH=false`. |
| `/v1/payments/*`, `/v1/stripe/*`, `/v1/paypal/*` | Paywall — not yet. |
| `/v1/integrations/*`, `/v1/task-integrations/*` | OAuth dances per provider — heavy lift. |
| `/v1/phone/*` | Phone-call feature — out of scope. |
| `/v1/import/*` | Limitless import — out of scope. |
| `/v3/upload-audio`, `/v2/sync-local-files`, `/v1/sync/audio/*`, `/v2/voice-message/*`, `/v2/tts/*`, `/v3/speech-profile`, `/v4/speech-profile`, `/v2/files` | Audio pipeline — out of scope. |
| `/v1/app/generate*` | LLM endpoints — heavy. |
| `/v1/users/migration/*` | Migration tooling. |
| `/v1/users/daily-summaries/*` | Optional. |
| `/v1/wrapped/2025/*` | Year-in-review feature. |
| `/v1/users/developer/webhook/*` | Developer settings. |
| `/v1/agent/*` REST | Companion to WS — skip with WS. |

---

## Health-check (optional but nice)

`GET /healthz` → `{"ok": true, "service": "omi-stub", "version": "0.1.0"}`. Not called by the app, but useful for ops.

---

## Smoke-test plan (mobile-side)

Once the stub is running on `http://localhost:8050/`:

1. Set `.dev.env::API_BASE_URL=http://localhost:8050/` (or use the runtime override; see `BACKEND_URL_OVERRIDE.md`).
2. `cd app && dart run build_runner build --delete-conflicting-outputs` (to regenerate `dev_env.g.dart`).
3. `fvm flutter run -d "iPhone 17"`.
4. **Expected:** App boots, skips onboarding (because `completed=true`), lands on home tab. Home shows empty conversations. Memories tab shows empty. Apps tab shows empty. No red error screen.
5. **Watch for:** Network log in Flutter inspector — every Bearer should be `dev-mock-dev-user-1`. Every 200 from boot-critical endpoints.

If the stub responds correctly to all TIER 1 + 2 endpoints, smoke is green.

---

## Tracking + handoff

- This doc is the contract. If Sub-Agent E sees an endpoint pattern that's missing here, **ask the Coordinator** before inventing a response shape. Mobile-side knows the actual call site.
- For response-body details beyond what's listed, grep the call site in `app/lib/backend/http/api/<area>.dart` — the JSON parsing happens right around the `http.get` call.
