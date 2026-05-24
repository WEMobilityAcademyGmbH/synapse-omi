# Desktop Strip Log — Phase 2.1

Branch: `feat/desktop-strip-mission-creep`
Worktree: `/Users/jonathan/code/synapse-omi-fork-desktop-strip/`
Start: 2026-05-24

## Mission

Strip Mission-Creep-Module aus OMI Desktop. Ziel: kleinerer, fokussierter Fork
ohne Cost-Center-Features (per-frame Gemini), ohne Telemetrie (PostHog),
ohne Always-On-Companion (Rewind), ohne Browser-Extension-Onboarding.

## Inventur vor Strip

```
desktop/Desktop/Sources/ insgesamt: 273 Swift-Files, 143014 LOC
```

| Modul | Files | LOC | Begründung Strip |
|---|---|---|---|
| ProactiveAssistants/ | 50 | 18641 | Per-frame Gemini, 6 Assistants, Cost-Center |
| AnalyticsManager.swift | 1 | 958 | Telemetrie nicht gewünscht |
| PostHogManager.swift | 1 | 730 | PostHog-Tracking |
| BrowserExtensionSetup.swift | 1 | 657 | Onboarding-Step für Browser-Ext, nicht gebraucht |
| Rewind/ | 31 | 17897 | **Behalten** — Core-Datenschicht. Siehe Entscheidung unten. |
| **Total Strip (geplant)** | **53** | **20986** | **~15% LOC-Reduktion** |

## Rewind-Entscheidung

**Behalten.** Begründung (entdeckt während Strip-Audit):
- `Rewind/Core/` enthält **Kern-Datenschicht**, nicht nur Always-On-Capture:
  - `MemoryStorage` — von MemoriesPage, AuthService, TierManager,
    MemoryExportService, ChatProvider, TasksStore, RecurringTaskScheduler
    genutzt.
  - `ProactiveStorage` — von AuthService (Cache-Invalidierung),
    ChatToolExecutor, OnboardingChatView.
  - `GoalStorage`, `ActionItemStorage`, `TaskChatMessageStorage`,
    `StagedTaskStorage`, `TranscriptionStorage` — alle von Tasks/Chat/
    Transcription-Pipeline referenziert.
  - `RewindDatabase` — gemeinsame GRDB-Datei für alle obigen Stores.
  - `MemoryModels`, `RewindModels`, `TranscriptionModels` — Datentypen
    quer durch App.
- 30+ Files querverlinkt (Apps/Conversations/Memories/Tasks/FileIndexing/
  Onboarding/Chat). Strip = totale App-Umschreibung, nicht in Phase 2.1.
- Continuous-screen-capture-Anteile (`VideoChunkEncoder`, `RewindIndexer`,
  `OCREmbeddingService`, `PowerMonitor`, Timeline-UI) sind technisch
  separable — Kandidat für **Phase 2.2 surgical Rewind-Strip**, nicht jetzt.

→ Rewind/ unangetastet. ~17.9k LOC bleiben. Stripped insgesamt: ~21k LOC.

## Strip-Reihenfolge

1. ProactiveAssistants (groesster Brocken zuerst)
2. Analytics + PostHog
3. BrowserExtensionSetup
4. Rewind
5. Build-Verify zwischendurch + final

## Build-Strategie

OMI Desktop benutzt `desktop/run.sh --yolo`. Wir nutzen `swift build` direkt
für schnelleren Verify-Loop. `.build/` Cache (~1.3GB) bleibt erhalten.

## Strip-Approach

Statt 100+ Call-Sites zu patchen: **Stub + Restore-Mix**, dann `git rm -rf`
der Originale.

### Stubs (Sources/ProactiveAssistantsStub.swift)

- `ProactiveAssistantsPlugin` (no-op monitoring, returns success / true).
- `FocusStatus` (data-only enum, kept for UI compat).
- `FocusAssistantStub` (zero counters).
- `AssistantCoordinator` (no-op `clearAllPendingWork`).
- `InsightStorage` (empty ObservableObject mit `unreadCount=0`).
- `FocusAssistantSettings` / `TaskAssistantSettings` / `MemoryAssistantSettings`
  / `InsightAssistantSettings` / `TaskAgentSettings` — in-memory only, kein
  Sync, kein Side-Effect.
- `TaskAgentManager` (no-op `restoreSessionsFromDatabase`).

### Stub-Views

- `MainWindow/Pages/FocusPage.swift` — Placeholder ("Focus disabled").
- `MainWindow/Pages/InsightPage.swift` — Placeholder ("Insights disabled").
- `Sources/BrowserExtensionSetup.swift` — Dismiss-sofort-Sheet.

### Files aus ProactiveAssistants/ nach Sources/ kopiert (Util-Layer)

Util-Code ohne Mission-Creep — relocated:
- `AssistantSettings.swift` (310 LOC — Transcription-Settings, kein Proactive).
- `GeminiClient.swift` (935 LOC — von LiveNotes + Floating Bar genutzt).
- `EmbeddingService.swift` (328 LOC — von ChatToolExecutor + Rewind/OCREmbeddingService genutzt).
- `AIUserProfileService.swift` (539 LOC — von Onboarding + AuthService genutzt).
- `SettingsSyncManager.swift` (171 LOC — von SettingsPage + Onboarding genutzt).
- `NotificationService.swift` (415 LOC — von OmiApp + CrispManager + AppState genutzt).
- `GoalGenerationService.swift` (141 LOC — von AppState + OnboardingView genutzt).
- `GoalsAIService.swift` (493 LOC — von OnboardingChatView + GoalsWidget genutzt).
- `GoalPrompts.swift` (102 LOC — Goal-AI-Prompts).
- `GoalModels.swift` (45 LOC — `GoalSuggestion`/`ProgressExtraction`).

### AnalyticsManager / PostHog

- `Sources/AnalyticsManager.swift` — komplett rewritten als No-Op-Stub mit
  allen 113 Public-Methods. Keine PostHog/FocusAssistantSettings-Refs mehr.
  Sentry-Crash-Reporting bleibt aktiv (separates Package).
- `Sources/PostHogManager.swift` — gelöscht.
- `Sources/Rewind/Core/VideoChunkEncoder.swift` — 1 Caller von
  `PostHogManager.shared.ffmpegResolved` auf No-Op geändert.

### Tests

- `Tests/DistributionDebounceTests.swift` gelöscht (testete stripped
  `ContextDetection`-Klasse).

## Package.swift

- `PostHog` Package + Product entfernt.
- Andere Deps unverändert (Firebase, Sentry, GRDB, Sparkle, MarkdownUI, onnx).

## Live-Inventur

| Metric | Vorher | Nachher | Δ |
|---|---|---|---|
| Swift-Files (Sources) | 273 | 233 | -40 (-14.7%) |
| Sources-LOC | 143014 | 124689 | -18325 (-12.8%) |

Die "Restore"-Files (~3.4k LOC) wurden mitgezählt — sie waren vorher unter
`ProactiveAssistants/` und sind jetzt unter `Sources/`. Reine ProactiveAssistants-
Reduktion: 50 Files / 18641 LOC → wegen Re-Hoisting effective ~15k stripped.

## Build-Verifikation

**Status: Syntax verified, Link blocked (environment)**

Per-File Syntax-Check via `swiftc -parse` für alle modifizierten + restorierten
Dateien — **alle ohne Fehler**.

Full `swift build` Verifikation blockiert: SwiftPM kann auf diesem Mac die
nötigen Binary-Artifacts (gRPC, Firebase, Sentry, GoogleAppMeasurement) nicht
herunterladen. `curl` zum gleichen Endpoint funktioniert; SwiftPM hängt
silent mit 0B in `.build/artifacts/`. Reproducible über mehrere Runs mit
verschiedenen Flags (`SWIFTPM_HTTP_TIMEOUT`, `-v`, clean .build/artifacts).
Umgebung: macOS 26.3, Swift 6.3.2, Xcode 17F42.

Workaround für Build-Verify: auf anderem Mac (Fabi) oder mit funktionierender
SwiftPM-Cache (z.B. ein voll gebauter OMI Desktop-Worktree) `swift build`
direkt nachfahren.

Erwartete Compile-Errors falls welche auftauchen sind:
- Mehr `*AssistantSettings`-Property-Accesses die ich nicht im
  Stub abgedeckt habe — fix: Stub erweitern (Pattern siehe vorhandene Properties).
- Möglich: ein `FocusEvent` / `ScreenAnalysis`-Restleak — fix: Stub-Type-Definition
  hinzufügen.
