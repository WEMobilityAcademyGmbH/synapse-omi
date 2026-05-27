# Backend URL Override — How To Use

**Date:** 2026-05-24
**Branch:** `feat/mobile-endpoint-pointing`

The mobile app can point at any backend at runtime without a rebuild. Two layers:

1. **Compile-time default** — `.dev.env::API_BASE_URL` (baked into `dev_env.g.dart` via `envied`).
2. **Runtime override** — persisted in SharedPreferences (`customBackendUrl` key), applied on every cold start in `lib/main.dart` right after `SharedPreferencesUtil.init()`.

The runtime override always wins.

---

## Setting the override in the running app

1. Open Settings → Developer Mode (must be enabled).
2. Scroll to **Custom Backend URL** section.
3. Tap **Open Custom Backend URL Form**.
4. Enter URL ending with `/` (e.g. `http://localhost:8050/`).
5. **Save**. Snackbar confirms. Form also calls `Env.overrideApiBaseUrl()` immediately so in-session calls swap right away.
6. For full effect (auth-flow + restored providers), restart the app.

To revert: same form, **Clear override (use default)** button. Then cold restart.

## Setting via `.dev.env` (rebuild path)

Used for the absolute baseline. Set `API_BASE_URL=http://...` in `app/.dev.env`, then:

```bash
cd app
dart run build_runner build --delete-conflicting-outputs   # regenerate dev_env.g.dart
# rebuild iOS / Android as usual
```

**Note:** the runtime override (if set) still wins over the new compile-time default. Clear it via the form if you want the compile-time URL to take effect.

## For Phase-1.1 smoke (stub server on localhost)

```
Backend URL: http://localhost:8050/
```

Sub-Agent E owns the stub. Endpoints in `BACKEND_REQUIREMENTS.md`.

## Source of changes

- `lib/backend/preferences.dart` — added `customBackendUrl` getter/setter + `hasCustomBackendUrl`.
- `lib/pages/onboarding/custom_auth/backend_url.dart` — was a dead stub; now persists + applies override + has clear-button.
- `lib/main.dart` — reads override after `SharedPreferencesUtil.init()` and calls `Env.overrideApiBaseUrl()` before any HTTP call.
- `lib/pages/settings/developer.dart` — new "Custom Backend URL" section that opens the form.
