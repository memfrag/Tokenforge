//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct HierarchyPane: View {

    @Bindable var document: TokenforgeDocument

    @Environment(\.undoManager) private var undoManager

    var body: some View {
        Pane {
            VStack(spacing: 0) {
                PaneHeader(
                    title: "Hierarchy",
                    subtitle: "Rules for how content competes for attention, and the emphasis scale the LLM uses to preserve it."
                ) {
                    EmptyView()
                }

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        HierarchyScreenSection(document: document, undoManager: undoManager)
                        Divider().opacity(0.35)
                        HierarchyRulesSection(document: document, undoManager: undoManager)
                        Divider().opacity(0.35)
                        HierarchyEmphasisScaleSection(document: document, undoManager: undoManager)
                        Divider().opacity(0.35)
                        HierarchyTypeEmphasisSection(document: document, undoManager: undoManager)
                        Spacer(minLength: 24)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .navigationTitle("Hierarchy")
    }
}

#Preview {
    HierarchyPane(document: TokenforgeDocument())
        .frame(width: 960, height: 720)
}
