import SwiftUI

// Phase 2.1 — ProactiveAssistants stripped.
// Original InsightPage (~647 LOC) consumed InsightStorage from the proactive
// stack. Replaced with a placeholder; sidebar entry stays so navigation
// indices don't shift.
struct InsightPage: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lightbulb.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Insights disabled")
                .font(.title2)
            Text("Proactive insights were removed in this build.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
