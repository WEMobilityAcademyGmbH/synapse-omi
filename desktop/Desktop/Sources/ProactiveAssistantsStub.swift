// ProactiveAssistantsStub.swift
//
// Phase 2.1 — Desktop Strip (feat/desktop-strip-mission-creep)
//
// The original ProactiveAssistants module (~18.6k LOC across 50 files) was a
// per-frame Gemini-driven screen-monitoring stack: FocusAssistant, TaskAssistant,
// InsightAssistant, MemoryAssistant, plus a coordinator + window monitor + glow
// overlays + prompt editors + test runners.
//
// We stripped the entire module (cost-center, not in our scope). This file
// stubs the public surface so the rest of the desktop app keeps compiling:
//
//   - ProactiveAssistantsPlugin (singleton, no-op monitoring API)
//   - AssistantCoordinator (no-op pending-work clearing)
//   - FocusStatus / FocusEvent (kept as data-only enum/struct, used by UI)
//   - FocusAssistant placeholder (so ResourceMonitor's optional probe compiles)
//
// AssistantSettings was preserved (transcription settings live there) and moved
// to Sources/AssistantSettings.swift.
//
// Any external caller that still routes through these stubs is a no-op; the
// monitoring loop is intentionally inert.

import Foundation
import AppKit
import SwiftUI
import UserNotifications

// MARK: - Focus Status (kept as data type for UI / storage compat)

enum FocusStatus: String, Codable {
    case focused
    case distracted
}

// MARK: - FocusAssistant placeholder

/// Inert placeholder. ResourceMonitor reads counters as a diagnostic probe;
/// returning zeros keeps the resource report well-formed without a monitor.
@MainActor
final class FocusAssistantStub {
    var pendingTasksCount: Int { 0 }
    var analysisHistoryCount: Int { 0 }
    func clearPendingWork() {}
}

// MARK: - AssistantCoordinator (no-op)

@MainActor
final class AssistantCoordinator {
    static let shared = AssistantCoordinator()
    private init() {}

    func clearAllPendingWork() {
        // No proactive assistants — nothing to clear.
    }
}

// MARK: - ProactiveAssistantsPlugin (no-op stub)

/// Stub replacement for the original ScreenCaptureKit-driven monitoring plugin.
/// All start/stop/monitor APIs are inert; permission accessors return `true`
/// so onboarding flows that gated on screen-recording-permission don't deadlock.
@MainActor
public final class ProactiveAssistantsPlugin: NSObject {

    public static let shared = ProactiveAssistantsPlugin()

    private override init() {
        super.init()
    }

    // MARK: Monitoring state (always idle)

    public private(set) var isMonitoring: Bool = false

    /// Counters exposed for diagnostic probes (ResourceMonitor). Always zero
    /// since nothing is capturing.
    public let droppedFrameCount: Int = 0
    public let isProcessingRewindFrame: Bool = false

    /// FocusAssistant probe — always nil so optional-chaining branches no-op.
    public var currentFocusAssistant: FocusAssistantStub? { nil }

    // MARK: Permissions

    /// Screen-recording permission accessor. We report `true` so flows that
    /// gated on this don't block — there is nothing being captured anyway.
    public var hasScreenRecordingPermission: Bool { true }

    public func refreshScreenRecordingPermission() {
        // No-op.
    }

    public func openScreenRecordingPreferences() {
        // No-op (was: open System Settings → Screen Recording).
    }

    // MARK: Monitoring control (no-op)

    public func startMonitoring(
        retryCount: Int = 0,
        completion: @escaping (Bool, String?) -> Void
    ) {
        // Inert. Signal success so callers proceed normally.
        completion(true, nil)
    }

    public func stopMonitoring() {
        // No-op.
    }

    public func toggleMonitoring() {
        // No-op.
    }

    // MARK: Notification registration repair

    /// Original implementation re-registered the bundle with LaunchServices so
    /// UNUserNotificationCenter would deliver. We keep a no-op so AppState's
    /// post-launch repair call compiles.
    static func repairNotificationRegistration() {
        // No-op.
    }
}

// MARK: - Per-assistant settings stubs
//
// The original ProactiveAssistants stack stored per-assistant tuning in
// dedicated *Settings classes. They're referenced from SettingsPage,
// TasksPage etc. We keep API-compatible stubs backed by UserDefaults
// (read-only defaults) so the UI compiles and toggles persist visually,
// even though no assistant is wired up.

@MainActor
final class FocusAssistantSettings {
    static let shared = FocusAssistantSettings()
    static let defaultAnalysisPrompt = ""
    private init() {}
    var isEnabled: Bool = false
    var notificationsEnabled: Bool = false
    var cooldownInterval: Int = 10
    var analysisPrompt: String = ""
    var excludedApps: Set<String> = []
    func excludeApp(_ name: String) { excludedApps.insert(name) }
    func includeApp(_ name: String) { excludedApps.remove(name) }
}

@MainActor
final class TaskAssistantSettings {
    static let shared = TaskAssistantSettings()
    static let defaultAnalysisPrompt = ""
    private init() {}
    var isEnabled: Bool = false
    var notificationsEnabled: Bool = false
    var extractionInterval: Int = 60
    var minConfidence: Double = 0.7
    var analysisPrompt: String = ""
    var allowedApps: Set<String> = []
    var browserKeywords: [String] = []
    func allowApp(_ name: String) { allowedApps.insert(name) }
    func disallowApp(_ name: String) { allowedApps.remove(name) }
    func addBrowserKeyword(_ keyword: String) { browserKeywords.append(keyword) }
    func removeBrowserKeyword(_ keyword: String) { browserKeywords.removeAll { $0 == keyword } }
}

@MainActor
final class MemoryAssistantSettings {
    static let shared = MemoryAssistantSettings()
    static let defaultAnalysisPrompt = ""
    private init() {}
    var isEnabled: Bool = false
    var notificationsEnabled: Bool = false
    var extractionInterval: Int = 60
    var minConfidence: Double = 0.7
    var analysisPrompt: String = ""
    var excludedApps: Set<String> = []
    func excludeApp(_ name: String) { excludedApps.insert(name) }
    func includeApp(_ name: String) { excludedApps.remove(name) }
}

@MainActor
final class InsightAssistantSettings {
    static let shared = InsightAssistantSettings()
    static let defaultAnalysisPrompt = ""
    private init() {}
    var isEnabled: Bool = false
    var notificationsEnabled: Bool = false
    var extractionInterval: Int = 60
    var minConfidence: Double = 0.7
    var analysisPrompt: String = ""
    var excludedApps: Set<String> = []
    func excludeApp(_ name: String) { excludedApps.insert(name) }
    func includeApp(_ name: String) { excludedApps.remove(name) }
}

@MainActor
final class TaskAgentSettings {
    static let shared = TaskAgentSettings()
    private init() {}
    var isEnabled: Bool = false
    var isChatEnabled: Bool = false
    var autoLaunch: Bool = false
    var skipPermissions: Bool = false
    var customPromptPrefix: String = ""
    var workingDirectory: String = ""
}

// MARK: - TaskAgentManager stub
//
// Original ~696 LOC TaskAgentManager spawned headless Claude-Code subagents
// for task execution. Replaced with a no-op so ViewModelContainer's
// restore-on-launch call resolves.

@MainActor
final class TaskAgentManager {
    static let shared = TaskAgentManager()
    private init() {}

    func restoreSessionsFromDatabase() async {
        // No sessions — TaskAgent stack stripped.
    }
}

// MARK: - InsightStorage stub (no insights ever)

@MainActor
final class InsightStorage: ObservableObject {
    static let shared = InsightStorage()
    @Published var unreadCount: Int = 0
    private init() {}
}

// MARK: - Notification name (kept for legacy listeners)

extension Notification.Name {
    /// Posted historically by the proactive-assistants stack on settings change.
    /// Kept for any straggler observers (AssistantSettings still posts it).
    static let proactiveAssistantsDidStrip = Notification.Name("proactiveAssistantsDidStrip")
}
