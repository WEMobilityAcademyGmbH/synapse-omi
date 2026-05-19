# Re-Use-Map — synapse-omi

Canonical mapping of what is **inherited from upstream**, **replaced**, and
**added** in this fork. The SYNAPSE monorepo carries an identical copy at
`omi-fork/Re-Use-Map.md` for ops reference.

Tracks: N-062 (Meeting-Recorder) parent L1-0376 / leaf L3-0650.

## 1. Übernommen (kept from upstream, unchanged or near-unchanged)

| Area | Upstream path | Why kept |
|---|---|---|
| WebSocket-Audio-Protokoll | `backend/routers/transcribe.py` (single-stream WS), `backend/pusher/` | Robust, battle-tested Opus framing + reconnect; basis for `/stream/dual` extension. |
| Memory-Pipeline | `backend/routers/memories.py`, `backend/utils/memories/`, `backend/database/memories.py` | Required for N-063 (Vault-Use-Case) — keep ABI stable so vault read-path continues to work. |
| Postprocessor-Hooks | `backend/utils/postprocessor*`, hook-points in `transcribe.py` | Provides clean extension surface for our Cleanup-Provider-Abstraktion without re-architecting the request lifecycle. |
| Diarizer / VAD interfaces | `backend/diarizer/`, `backend/modal/` (VAD) | Re-used for speaker labelling (L1-0378) — public interfaces stable enough. |
| Firestore + Redis adapters | `backend/database/` | Keep for memory-pipeline continuity; SYNAPSE-side Postgres bus is additive, not a replacement here. |
| MIT `LICENSE` | `LICENSE` | License preservation, see `LICENSE-NOTICE.md`. |

## 2. Ersetzt (removed or replaced)

| Area | Upstream path | Replacement | Why |
|---|---|---|---|
| Mobile-Wearable-App | `app/` (Flutter) | none in this fork | We don't ship a mobile companion. Capture-Quelle is Mac (L1-0375) / Win (L1-0380). |
| Wearable firmware | `omi/`, `omiGlass/`, `hardware/`, `firmware/` | none | Hardware out of scope; OMI armband connects via L1-0377 (BLE adapter), not via wearable firmware. |
| Desktop client | `desktop/` (macOS native) | SYNAPSE Mac Capture-Core (L1-0375) | We build our own ScreenCaptureKit + AVAudioEngine companion. |
| Auth / OAuth flows | `backend/routers/auth.py`, `oauth.py`, `custom_auth.py` | SYNAPSE workspace-token (tenants/*) | Multi-tenant SYNAPSE owns identity; OMI's social-login is removed from server image. |
| Payment / fair-use admin | `backend/routers/payment.py`, `fair_use_admin.py` | none | SaaS billing not relevant — internal use only. |
| Plugins / apps marketplace | `backend/routers/plugins.py`, `apps.py`, `community-plugins.json` | none | Marketplace surface not relevant for internal pipeline. |
| Mobile-only routes | `firmware.py`, `calendar_meetings.py`, `calendar_onboarding.py`, `notifications.py`, `wrapped.py`, `goals.py`, `trends.py` | none | Tied to mobile UX; removed from server image to shrink attack surface and dependency footprint. |
| Helm charts | `backend/charts/` | Docker Compose snippet (Hetzner) | We deploy via Compose on Hetzner, not k8s. See `deploy/Dockerfile` + `deploy/docker-compose.snippet.yml`. |

> Removal happens lazily: files stay in the upstream tree until first
> conflicting upstream-merge. The Compose build context only `COPY`s the
> subset we ship — image is small even if the working tree is large.

## 3. Ergänzt (added — net-new in this fork)

| Feature | Path | Owner-Node | Notes |
|---|---|---|---|
| `/stream/dual` endpoint | `backend/routers/stream_dual.py` *(new)* | L1-0376 | Two **separate** WebSocket connections (mic + system-out), Opus frames each. Robust against single-source drop. |
| `/transcribe-snippet` endpoint | `backend/routers/transcribe_snippet.py` *(new)* | L1-0376 AC | Dictation-Mode: synchronous response (1-2s) for short Mac-Dictation snippets. Avoids a second endpoint when N-066 lands. |
| Cleanup-Provider-Abstraktion | `backend/cleanup_providers/` *(new)* | L1-0376 AC | Plugin interface: `local-haiku` (Hetzner/Mac), `anthropic-haiku-api`, `anthropic-sonnet-api`, `openai-gpt-mini-api`. Per-user / per-tenant config. Re-used by N-063 coaching + N-064 business-call classifier. |
| Capture-Event-Bus emitter | `backend/bus/capture_emitter.py` *(new)* | L1-0374 | Emits transcript chunks via Postgres-Outbox to the SYNAPSE Capture-Event-Bus (ADR-063 / D-0137). Schema: `libs/synapse-common/capture_event.py`. |
| Faster-Whisper streaming layer | `backend/asr/faster_whisper_stream.py` *(new)* | L1-0376 | Replaces OMI's Deepgram-default with a self-hosted faster-whisper path; Deepgram path stays available as fallback provider. |
| Hetzner deploy bundle | `deploy/Dockerfile`, `deploy/docker-compose.snippet.yml` *(new)* | L3-0650 | Single-image Compose service `synapse-omi` on port 8030, mounts model cache, picks up bus DSN from env. |
| `LICENSE-NOTICE.md` | `LICENSE-NOTICE.md` *(new)* | L3-0650 | Records fork lineage + maintainer + scope of additions. |
| `Re-Use-Map.md` | `Re-Use-Map.md` *(new — this file)* | L3-0650 | Canonical mapping. Mirrored at `omi-fork/Re-Use-Map.md` in SYNAPSE monorepo. |

## 4. Forward integration

- `node/L1-0376` opens the WS-multi-stream endpoint and wires faster-whisper.
- `node/L1-0377` adds the OMI-Armband BLE adapter as a third capture source
  (no firmware change).
- `node/L0-0062` aggregates L1-0374..L1-0382 — `synapse-omi` is one
  deployable artefact of that L0 milestone.

## 5. Upstream-Sync policy

- Track `upstream/main` weekly; merge into local `main` via PR.
- Conflicts in **kept** areas (table 1) → resolve carefully, keep upstream
  behaviour.
- Conflicts in **replaced** areas (table 2) → take ours.
- New upstream features → review case-by-case; default is "don't pull"
  unless they touch areas we kept.

## 6. License & attribution

See [`LICENSE-NOTICE.md`](LICENSE-NOTICE.md). Upstream MIT preserved.
