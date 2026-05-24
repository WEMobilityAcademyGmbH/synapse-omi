import AppKit
import Foundation

// Phase 2.1 — Desktop Strip (feat/desktop-strip-mission-creep).
//
// Original AnalyticsManager (~958 LOC) fanned all UI/runtime events out to
// PostHog. Telemetry is removed from this build. We keep the class + every
// public method signature as no-ops so call sites compile unchanged.
//
// PostHogManager.swift was deleted in the same commit; the PostHog Swift
// Package dependency is removed from Package.swift.
//
// `trackFirstLaunchIfNeeded` still flips the "hasLaunchedBefore" UserDefaults
// flag because other code paths assume it.
@MainActor
class AnalyticsManager {
  static let shared = AnalyticsManager()

  /// Returns true for non-production Omi bundles. Retained because callers
  /// branch on this independently of the analytics pipeline.
  nonisolated static var isDevBuild: Bool {
    AppBuild.isNonProduction
  }

  private init() {}

  // MARK: - Initialization / Identity

  func initialize() {}
  func identify() {}
  func reset() {}
  func optInTracking() {}
  func optOutTracking() {}

  // MARK: - Onboarding

  func onboardingStepCompleted(step: Int, stepName: String) {}
  func onboardingHowDidYouHear(source: String) {}
  func onboardingCompleted() {}
  func onboardingChatToolUsed(tool: String, properties: [String: Any] = [:]) {}
  func onboardingChatMessage(role: String, step: String) {}
  func onboardingChatMessageDetailed(
    role: String, text: String, step: String, toolCalls: [String]? = nil,
    model: String? = nil, error: String? = nil
  ) {}

  // MARK: - Auth

  func signInStarted(provider: String) {}
  func signInCompleted(provider: String) {}
  func signInFailed(provider: String, error: String) {}
  func signedOut() {}

  // MARK: - Monitoring (proactive-assistants stripped, kept as no-ops)

  func monitoringStarted() {}
  func monitoringStopped() {}
  func distractionDetected(app: String, windowTitle: String?) {}
  func focusRestored(app: String) {}

  // MARK: - Recording / Transcription

  func transcriptionStarted() {}
  func transcriptionStopped(wordCount: Int) {}
  func recordingError(error: String) {}

  // MARK: - Permissions

  func permissionRequested(permission: String, extraProperties: [String: Any] = [:]) {}
  func permissionGranted(permission: String, extraProperties: [String: Any] = [:]) {}
  func permissionDenied(permission: String, extraProperties: [String: Any] = [:]) {}
  func permissionSkipped(permission: String, extraProperties: [String: Any] = [:]) {}

  func bluetoothStateChanged(
    oldState: String, newState: String, oldStateRaw: Int, newStateRaw: Int,
    authorization: String, authorizationRaw: Int
  ) {}

  func screenCaptureBrokenDetected() {}
  func screenCaptureResetClicked(source: String) {}
  func screenCaptureResetCompleted(success: Bool) {}

  func notificationRepairTriggered(
    reason: String, previousStatus: String, currentStatus: String
  ) {}

  func notificationSettingsChecked(
    authStatus: String, alertStyle: String, soundEnabled: Bool,
    badgeEnabled: Bool, bannersDisabled: Bool
  ) {}

  // MARK: - Crash detection

  /// No-op: crash reporting now lives in Sentry only.
  func detectAndReportCrash() {}

  // MARK: - App lifecycle

  func appLaunched() {}

  func trackStartupTiming(
    dbInitMs: Double, timeToInteractiveMs: Double, hadUncleanShutdown: Bool,
    databaseInitFailed: Bool
  ) {}

  /// Preserves the `hasLaunchedBefore` flip — other code paths read this.
  func trackFirstLaunchIfNeeded() {
    let defaults = UserDefaults.standard
    let key = "hasLaunchedBefore"
    guard !defaults.bool(forKey: key) else { return }
    defaults.set(true, forKey: key)
  }

  func appBecameActive() {}
  func appResignedActive() {}

  // MARK: - Conversations / Memories

  func conversationCreated(
    conversationId: String, source: String, durationSeconds: Int? = nil
  ) {}
  func memoryDeleted(conversationId: String) {}
  func memoryShareButtonClicked(conversationId: String) {}
  func shareAction(category: String, properties: [String: Any] = [:]) {}
  func memoryListItemClicked(conversationId: String) {}

  // MARK: - Chat

  func chatMessageSent(messageLength: Int, hasContext: Bool = false, source: String) {}

  // MARK: - Search

  func searchQueryEntered(query: String) {}
  func searchBarFocused() {}

  // MARK: - Settings

  func settingsPageOpened() {}
  func pageViewed(_ pageName: String) {}
  func deleteAccountClicked() {}
  func deleteAccountConfirmed() {}
  func deleteAccountCancelled() {}

  // MARK: - Navigation

  func tabChanged(tabName: String) {}
  func conversationDetailOpened(conversationId: String) {}

  // MARK: - Chat (additional)

  func chatAppSelected(appId: String?, appName: String?) {}
  func chatCleared() {}
  func chatSessionCreated() {}
  func chatSessionDeleted() {}
  func messageRated(rating: Int) {}
  func initialMessageGenerated(hasApp: Bool) {}
  func sessionTitleGenerated() {}
  func chatStarredFilterToggled(enabled: Bool) {}
  func sessionRenamed() {}

  // MARK: - Claude Agent

  func chatAgentQueryCompleted(
    durationMs: Int, toolCallCount: Int, toolNames: [String],
    costUsd: Double, messageLength: Int
  ) {}
  func chatToolCallCompleted(toolName: String, durationMs: Int) {}
  func chatAgentError(error: String, rawError: String? = nil) {}

  func conversationReprocessed(conversationId: String, appId: String) {}

  // MARK: - Settings (additional)

  func settingToggled(setting: String, enabled: Bool) {}
  func languageChanged(language: String) {}

  // MARK: - Launch at login

  func launchAtLoginStatusChecked(enabled: Bool) {}
  func launchAtLoginChanged(enabled: Bool, source: String) {}

  // MARK: - Feedback

  func feedbackOpened() {}
  func feedbackSubmitted(feedbackLength: Int) {}

  // MARK: - Rewind (desktop)

  func rewindSearchPerformed(queryLength: Int) {}
  func rewindScreenshotViewed(timestamp: Date) {}
  func rewindTimelineNavigated(direction: String) {}

  // MARK: - Proactive (stripped)

  func focusAlertShown(app: String) {}
  func focusAlertDismissed(app: String, action: String) {}
  func taskExtracted(taskCount: Int) {}
  func taskPromoted(taskCount: Int) {}
  func taskCompleted(source: String?) {}
  func taskDeleted(source: String?) {}
  func taskAdded() {}
  func memoryExtracted(memoryCount: Int) {}
  func insightGenerated(category: String?) {}

  // MARK: - Apps

  func appEnabled(appId: String, appName: String) {}
  func appDisabled(appId: String, appName: String) {}
  func appDetailViewed(appId: String, appName: String) {}

  // MARK: - Updates

  func updateCheckStarted() {}
  func updateAvailable(version: String) {}
  func updateInstalled(version: String) {}
  func updateNotFound() {}
  func updateCheckFailed(
    error: String, errorDomain: String, errorCode: Int,
    underlyingError: String? = nil, underlyingDomain: String? = nil,
    underlyingCode: Int? = nil
  ) {}

  // MARK: - Notifications

  func notificationSent(
    notificationId: String, title: String, assistantId: String, surface: String
  ) {}
  func notificationClicked(
    notificationId: String, title: String, assistantId: String, surface: String
  ) {}
  func notificationDismissed(
    notificationId: String, title: String, assistantId: String, surface: String
  ) {}
  func notificationWillPresent(notificationId: String, title: String) {}
  func notificationDelegateReady() {}

  // MARK: - Menu bar

  func menuBarOpened() {}
  func menuBarActionClicked(action: String) {}

  // MARK: - Tier

  func tierChanged(tier: Int, reason: String) {}
  func chatBridgeModeChanged(from oldMode: String, to newMode: String) {}

  // MARK: - Settings state (no-op)

  func trackSettingsState(
    screenshotsEnabled: Bool, memoryExtractionEnabled: Bool,
    memoryNotificationsEnabled: Bool
  ) {}

  func reportAllSettingsIfNeeded() {}

  // MARK: - Floating bar

  func floatingBarToggled(visible: Bool, source: String) {}
  func floatingBarAskOmiOpened(source: String) {}
  func floatingBarAskOmiClosed() {}
  func floatingBarQuerySent(messageLength: Int, hasScreenshot: Bool) {}
  func floatingBarPTTStarted(mode: String) {}
  func floatingBarPTTEnded(mode: String, hadTranscript: Bool, transcriptLength: Int) {}

  // MARK: - Knowledge graph

  func knowledgeGraphBuildStarted(filesIndexed: Int, hadExistingGraph: Bool) {}
  func knowledgeGraphBuildCompleted(
    nodeCount: Int, edgeCount: Int, pollAttempts: Int, hadExistingGraph: Bool
  ) {}
  func knowledgeGraphBuildFailed(reason: String, pollAttempts: Int, filesIndexed: Int) {}

  // MARK: - Display

  func trackDisplayInfo() {}
}
