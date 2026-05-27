# OMI Mobile — Auth Strategy for atwenture-Backend

**Date:** 2026-05-24
**Branch:** `feat/mobile-endpoint-pointing`
**Decision:** **Option B2 (Auth-Bypass / Mock-JWT, dev-only)** for the immediate Phase-1.1 smoke. Plan to upgrade to **Option B1 (own Firebase project)** before any wider testing.

---

## Context

OMI's mobile client sends `Authorization: Bearer <firebase-id-token>` on every authenticated call (`lib/backend/http/shared.dart:42-86`). The token is a real Firebase JWT issued by BasedHardware's Firebase project, refreshed at startup via `AuthService.instance.getIdToken()` (calls `FirebaseAuth.instance.currentUser?.getIdTokenResult(true).token`).

Two complications:
1. The mobile app is built against `app/ios/Runner/GoogleService-Info.plist` + `app/android/app/google-services.json` from BasedHardware's Firebase project. Those files are gitignored — they don't ship in the fork. Building the app from scratch on a fresh checkout therefore already needs a Firebase project decision.
2. The Phase-1 smoke (Stage 1.0) presumably re-used BasedHardware's prebuilt config (`setup.sh` downloads them). To swap backend, we have to either keep using BasedHardware's Firebase (Option A) or own our identity stack end-to-end (Option B*).

---

## Options evaluated

### Option A — Use BasedHardware's Firebase project
- App keeps the prebuilt config. Login flow stays the same.
- Our Hetzner backend would have to validate JWTs signed by BasedHardware's project — i.e. we'd need their public-key set, which we can fetch from `https://securetoken.google.com/<project-id>/.well-known/openid-configuration`.
- **Rejected.** We don't control the project. User IDs are theirs. Locks us in.

### Option B1 — Our own Firebase project (cleanest)
- `flutterfire config --project=atwenture-omi-dev` regenerates `firebase_options.dart` + `GoogleService-Info.plist` + `google-services.json`.
- Requires Firebase CLI: `npm install -g firebase-tools && curl -sL https://firebase.tools | bash` (or `npm i -g firebase-tools`). **Not installed locally** (`which firebase` → not found).
- Time-cost: ~30 min Firebase Console setup + `flutterfire config` + rebuild.
- Backend stub validates Firebase ID-tokens against our project's JWKS.
- **Best end-state.** We own user IDs end-to-end.

### Option B2 — Auth-bypass / Mock-JWT (fastest demo)
- Patch `app/lib/backend/http/shared.dart` to send `Bearer dev-mock-<user-id>` when `Env.apiBaseUrl` points at localhost/atwenture-dev host.
- Stub-server (Sub-Agent E) accepts any token prefixed `dev-mock-`.
- Bypasses Firebase entirely on the client (we still need a Firebase project to satisfy `FirebaseAuth.instance.initializeApp()` at startup, but we never `signInWithCredential` — we just inject a fake `uid` into SharedPreferences).
- **Tech debt.** Has to be ripped out before any wider testing. Marked with `TODO(auth-bypass)` comments.

### Option B3 — Hetzner-native OAuth (long-term clean)
- Eigener OAuth-Endpoint auf Hetzner. App-Flow: `POST /v1/auth/login` → JWT → Bearer.
- Requires rewriting `AuthService` substantially.
- **Out of scope for Phase 1.1.** Park for later, after we know what the actual app coverage looks like.

---

## Chosen path

**Phase 1.1 (this branch, today):** Option B2.
**Phase 1.2 (follow-up branch, before wider testing):** Upgrade to Option B1.

### Why B2 now

- Firebase CLI is **not installed** on this machine. Installing + creating a project + configuring iOS/Android apps + downloading config files + rebuilding = unbounded yak-shave that risks blowing the 1-hour build-time budget.
- The first goal is **proving the URL-override mechanism works** and that the stub backend can answer the boot-critical endpoints. Auth is orthogonal to that. We can fake the JWT.
- The patch is small and self-contained — `lib/backend/http/shared.dart` already has a place to plug in `_apiBaseUrlOverride`-style logic.

### Implementation of B2

1. In `lib/backend/http/shared.dart`, the `_getAuthHeader()` function returns `'Bearer <token>'`. We **don't** patch it — instead we:
   - In `lib/main.dart`, after `Env.apiBaseUrl` is set from SharedPreferences (see `BACKEND_URL_OVERRIDE.md` for the override-flow), check if the URL points at the dev-host whitelist (`localhost`, `127.0.0.1`, `omi-dev.atwenture.de`, anything in `.dev.env::DEV_AUTH_BYPASS_HOSTS`).
   - If yes, set `SharedPreferencesUtil().authToken = 'dev-mock-<uid>'` and `SharedPreferencesUtil().uid = 'dev-user-1'`.
   - This skips the entire Firebase signin flow.
2. Onboarding-gate: set `SharedPreferencesUtil().onboardingCompleted = true` in the same dev-bypass path.
3. Backend-stub-server (Sub-Agent E) trusts any `Authorization: Bearer dev-mock-*`.

### Migration to B1

When ready: install Firebase CLI, create `atwenture-omi-dev` project, run `flutterfire config`, drop new config files into ignored paths, rebuild, remove the `dev-mock-*` shortcut. Stub server starts requiring real JWKS validation.

---

## Concrete TODOs for Phase 1.2

- [ ] `npm install -g firebase-tools`
- [ ] Create `atwenture-omi-dev` Firebase project via console
- [ ] Register iOS bundle-id `com.atwenture.omi.dev`, download `GoogleService-Info.plist` → `app/ios/Runner/`
- [ ] Register Android `com.atwenture.omi.dev`, download `google-services.json` → `app/android/app/`
- [ ] `cd app && flutterfire config --platforms=ios,android --out=lib/firebase_options_dev.dart --project=atwenture-omi-dev`
- [ ] Backend stub: add JWKS validation against `https://securetoken.google.com/atwenture-omi-dev`
- [ ] Remove `dev-mock-*` bypass from `lib/main.dart`

---

## Source files touched in B2 (this commit-set)

- `lib/main.dart` — dev-bypass block in boot flow (after URL override is loaded)
- `lib/pages/onboarding/custom_auth/backend_url.dart` — persisted URL form (see `BACKEND_URL_OVERRIDE.md`)
- `lib/backend/preferences.dart` — `customBackendUrl` getter/setter

Tagged in code with `// TODO(auth-bypass-B2)` comments for grep-discoverability.
