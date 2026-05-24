# Endpoint-Pointing Notes — How to swap OMI-Cloud → atwenture-Backend

**Status:** App currently points at OMI-Cloud (`https://api.omiapi.com/`) by default. This doc maps the wiring so we can later swap to our own Hetzner-backend.

---

## 1. Where the default URL lives

### Source of truth: `.dev.env` (gitignored)
```
API_BASE_URL=https://api.omiapi.com/
USE_WEB_AUTH=true
USE_AUTH_CUSTOM_TOKEN=true
```
Created by `setup.sh` (`function setup_app_env`). Value is hardcoded in the script as `API_BASE_URL=https://api.omiapi.com/`.

### Compile-time injection: `lib/env/dev_env.dart`
The `envied` package reads `.dev.env` at `dart run build_runner build` time and bakes the values into `lib/env/dev_env.g.dart` (obfuscated). So **the URL is baked into the binary** at build time, not read at runtime.

### Runtime access: `lib/env/env.dart`
```dart
static String? get apiBaseUrl => _apiBaseUrlOverride ?? _instance.apiBaseUrl;
static void overrideApiBaseUrl(String url) { _apiBaseUrlOverride = url; }
```
There **is** a runtime override mechanism (`Env.overrideApiBaseUrl`), but only one caller uses it — TestFlight staging-toggle in `lib/main.dart:159`.

### Prod env
`lib/env/prod_env.g.dart` line 17: `apiBaseUrl = null` — production reads URL from elsewhere (likely Firebase config or hardcoded). For dev flavor what's in `.dev.env` wins.

---

## 2. How a user can change the URL (current state)

### Custom Backend URL Form: NON-FUNCTIONAL STUB
`lib/pages/onboarding/custom_auth/backend_url.dart` exists as a UI form with a text field for custom URL, but:
```dart
void _submitForm() {
  if (_formKey.currentState!.validate()) {
    String backendURL = _urlController.text;
    print('Custom Backend URL: $backendURL');  // ← just prints
    ScaffoldMessenger.of(context).showSnackBar(...);  // ← just shows toast
  }
}
```
**The form does NOT persist the URL or call `Env.overrideApiBaseUrl()`.** Looks like dead/incomplete code. Whether this is reachable from the UI in the current build: untested (TODO: navigate through onboarding to find).

### TestFlight staging-toggle: only path that actually overrides
`lib/main.dart:152-167` — if `F.env == Environment.prod` AND `isTestFlight == true` AND `SharedPreferencesUtil().testFlightUseStagingApi == true`, then `Env.overrideApiBaseUrl(stagingApiUrl)` is called.
- `STAGING_API_URL` would need to be in `.prod.env` (we only created `.dev.env`).
- Toggle is in user settings (not yet located in code).
- Not usable for arbitrary URLs — only the one staging URL baked in at build.

**Bottom line:** there is no end-user mechanism to point the app at our backend. We have to:
- Either (a) put our URL in `.dev.env` and rebuild,
- Or (b) extend the custom-backend form to actually call `Env.overrideApiBaseUrl(...)` and persist via `SharedPreferencesUtil`,
- Or (c) build our own dev flavor (`prebuilt` Firebase config + our API URL).

---

## 3. Auth headers + auth flow

### Header: Bearer Firebase JWT
`lib/backend/http/shared.dart:42-86`:
```dart
return 'Bearer ${SharedPreferencesUtil().authToken}';
// authToken is refreshed via:
SharedPreferencesUtil().authToken = await AuthService.instance.getIdToken() ?? '';
// = FirebaseAuth.instance.currentUser?.getIdTokenResult(true).token
```
Every authenticated API call has `Authorization: Bearer <firebase-id-token>`. Backend must verify with Firebase Admin SDK.

### Auth Flow (web-auth + custom-token, since `USE_WEB_AUTH=true`):
1. App opens `https://{backend}/v1/auth/authorize?provider=google|apple&redirect_uri=omi://auth/callback&...` in browser.
2. Backend handles OAuth dance with Google/Apple.
3. Backend redirects to `omi://auth/callback?code=...`.
4. App calls `POST {backend}/v1/auth/token` with the code → backend returns:
   ```json
   { "custom_token": "<firebase-custom-token>", "user_id": "...", ... }
   ```
5. App calls `FirebaseAuth.instance.signInWithCustomToken(customToken)` → Firebase returns an ID-Token.
6. App stores ID-Token in `SharedPreferencesUtil().authToken`. All subsequent calls send it.

### Alternative auth path (`USE_WEB_AUTH=false`)
Direct mobile-SDK Google/Apple sign-in → `FirebaseAuth.signInWithCredential(googleCredential)`. Backend just verifies the resulting Firebase ID-Token. **Simpler for our stub.**

---

## 4. Critical routes for app-bootup

App startup calls these (early-startup, blocks UI if they fail):

| Route | When | Required? |
|---|---|---|
| `GET v1/users/private-cloud-sync` | Right after login | likely yes |
| `GET v1/users/me/subscription` | Settings + paywall logic | optional first-boot |
| `GET v1/users/me/usage?period=...` | Usage page (lazy) | no, lazy |
| `GET v1/conversations/?offset=0&limit=...` | Home tab | no, lazy |
| `GET v1/apps/enabled` | Apps tab | no, lazy |
| `GET v1/fair-use/status` | Per-action limits | likely |
| `POST v1/users/fcm-token` | FCM registration | optional |

### Onboarding (first-launch)
- `GET v1/users/onboarding` (and PUT to update state)
- `GET v1/users/profile`
- Possibly `POST v1/users/language` if locale differs

### Auth-specific (must work for sign-in)
- `GET v1/auth/authorize?...` (web-auth path)
- `POST v1/auth/token` (web-auth code exchange)
- Firebase Auth SDK does the JWT issuance itself — backend just needs to validate

---

## 5. Minimum stubs Hetzner-backend needs for App-Login

Goal: app should boot past onboarding and show home tab with empty state. Minimum endpoint surface:

### Phase 1 (sign-in, no data)
- **Firebase Admin SDK integration** (backend verifies Bearer JWT against our Firebase project).
- `GET /v1/users/onboarding` → returns `{"completed": false}` or persisted state
- `PUT /v1/users/onboarding` → accept JSON body, return 200
- `GET /v1/users/profile` → returns minimal `{user_id, email, name}`
- `POST /v1/users/fcm-token` → 200 (we don't need FCM at first)
- `POST /v1/users/store-recording-permission` → 200 (no-op)
- `GET /v1/users/private-cloud-sync` → `{"enabled": false}`

### Phase 2 (data — empty state)
- `GET /v1/conversations/?...` → `[]`
- `GET /v1/apps/enabled` → `[]`
- `GET /v1/announcements/pending` → `[]`
- `GET /v1/fair-use/status` → `{"unlimited": true}` or sensible default
- `GET /v1/users/me/subscription` → `{"tier": "free", ...}`
- `GET /v1/action-items/` → `[]`

### Phase 3 (actual feature work)
Real conversation ingest, memory pipeline, app/MCP integration — those are the meaty endpoints. Skip for v0.

### Auth strategy options
- **Option A (simplest):** Use BasedHardware's Firebase project (the prebuilt config) and only stub the `/v1/...` routes. Our backend verifies any valid BasedHardware Firebase JWT.
- **Option B (cleanest):** Run `flutterfire config` against our own Firebase project, rebuild app with our config files. Then our backend verifies our own Firebase JWTs.
- **Option C (auth-bypass for dev only):** Add a dev-only `X-Dev-Auth: <static-token>` header path in `lib/backend/http/shared.dart` and matching server-side allowlist. Fastest, but tech-debt — must be ripped out before any prod use.

**Recommendation:** Option B. ~30 min Firebase project setup, no auth surprises later. We control user-IDs end-to-end.

---

## 6. Concrete swap-path (when we're ready)

1. **Backend stubs ready** at e.g. `https://omi-api.atwenture.de/v1/...`.
2. **Decide auth strategy** (recommend Option B above).
3. **Edit `.dev.env`** (or create a new flavor `atwenture.env`):
   ```
   API_BASE_URL=https://omi-api.atwenture.de/
   USE_WEB_AUTH=false       # easier for v0
   USE_AUTH_CUSTOM_TOKEN=false
   ```
4. **(Option B)** Run `flutterfire config --platforms=ios,android --out=lib/firebase_options_dev.dart --project=<our-firebase-project> ...` — overrides the prebuilt Firebase config.
5. **Rebuild:** `dart run build_runner build --delete-conflictiing-outputs && cd ios && pod install && cd .. && fvm flutter build ios --debug --simulator --flavor dev --no-codesign -d <sim-id>`.
6. **Smoke:** install in simulator, sign in with Google → land in onboarding/home.

### Optional: make backend URL switchable at runtime
Wire `backend_url.dart` form to actually:
```dart
Env.overrideApiBaseUrl(backendURL);
SharedPreferencesUtil().customBackendUrl = backendURL;  // need to add field
// On app start: if customBackendUrl != null: Env.overrideApiBaseUrl(stored)
```
~30 min work. Useful for QA/Fabi switching between cloud + Hetzner without rebuild.
