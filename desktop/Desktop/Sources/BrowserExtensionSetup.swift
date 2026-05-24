import SwiftUI

// Phase 2.1 — Desktop Strip (feat/desktop-strip-mission-creep).
//
// Original BrowserExtensionSetup (~657 LOC) was a multi-phase onboarding
// flow for installing the Playwright MCP Chrome extension. We are dropping
// the Playwright/browser-extension onboarding path from this build.
//
// The class is kept as a minimal stub so existing call sites (ChatPage,
// SettingsPage) compile. Presenting the sheet immediately invokes
// `onDismiss` (or `onSkip`, falling back to `onComplete`) so the flow is
// effectively skipped.
struct BrowserExtensionSetup: View {
    var onComplete: () -> Void
    var onSkip: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil

    /// Kept for API compatibility with the original call sites.
    var chatProvider: ChatProvider? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "puzzlepiece.extension")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text("Browser extension setup removed")
                .font(.headline)
            Text("This build does not include the Playwright Chrome-extension flow.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            Button("Close") {
                let dismiss = onDismiss ?? onSkip ?? onComplete
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(40)
        .frame(minWidth: 420, minHeight: 240)
    }
}
