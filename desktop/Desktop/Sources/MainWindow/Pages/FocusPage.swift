import SwiftUI

// Phase 2.1 — ProactiveAssistants stripped.
// Original FocusPage (~764 LOC) was the UI for the FocusAssistant
// continuous-monitoring stack (FocusStorage, GlowOverlay, prompt editors).
// Replaced with a placeholder so SidebarView / DesktopHomeView still resolve
// the symbol.
struct FocusPage: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "eye.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Focus monitoring disabled")
                .font(.title2)
            Text("This build does not include the proactive screen-monitoring assistant.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
