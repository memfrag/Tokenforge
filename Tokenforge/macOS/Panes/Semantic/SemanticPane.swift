//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct SemanticPane: View {

    @Bindable var document: TokenforgeDocument

    @Environment(\.undoManager) private var undoManager

    var body: some View {
        Pane {
            VStack(spacing: 0) {
                PaneHeader(
                    title: "Semantic",
                    subtitle: "Aliases layered on primitives. Colors reference one light and one dark primitive."
                ) {
                    EmptyView()
                }

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        SemanticColorSection(document: document, undoManager: undoManager)
                        Divider().opacity(0.35)
                        SemanticTypeSection(document: document, undoManager: undoManager)
                        Divider().opacity(0.35)
                        SemanticSpacingSection(document: document, undoManager: undoManager)
                        Divider().opacity(0.35)
                        SemanticRadiusSection(document: document, undoManager: undoManager)
                        Spacer(minLength: 24)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .navigationTitle("Semantic")
    }
}

#Preview {
    SemanticPane(document: TokenforgeDocument())
        .frame(width: 960, height: 720)
}
