//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

public struct HelpWindow: Scene {

    public static let windowID = "help"

    public var body: some Scene {
        Window("Tokenforge Help", id: Self.windowID) {
            HelpWindowContent()
                .frame(minWidth: 680, minHeight: 520)
        }
        .commandsRemoved() // Don't show window in Windows menu
        .defaultPosition(.center)
        .defaultSize(width: 820, height: 680)
        .windowResizability(.contentMinSize)
    }
}

/// Loads `AuthoringGuide.md` from the main bundle and renders it via the
/// lightweight `AuthoringGuideView`. Falls back to a short friendly error
/// if the resource is missing (which should never happen in shipping
/// builds, but keeps the Help window from crashing if it does).
///
private struct HelpWindowContent: View {

    @State private var markdown: String = ""
    @State private var loadError: String?

    var body: some View {
        Group {
            if let loadError {
                VStack(spacing: 12) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 42, weight: .regular))
                        .foregroundStyle(.tertiary)
                    Text("Help unavailable")
                        .font(.system(size: 15, weight: .semibold))
                    Text(loadError)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                AuthoringGuideView(markdown: markdown)
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "AuthoringGuide", withExtension: "md") else {
            loadError = "The authoring guide resource was not found in the app bundle."
            return
        }
        do {
            markdown = try String(contentsOf: url, encoding: .utf8)
        } catch {
            loadError = "Failed to read the authoring guide: \(error.localizedDescription)"
        }
    }
}
