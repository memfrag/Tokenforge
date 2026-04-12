//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct PrimitivesPane: View {

    @Bindable var document: TokenforgeDocument

    @Environment(\.undoManager) private var undoManager

    var body: some View {
        Pane {
            VStack(spacing: 0) {
                PaneHeader(
                    title: "Primitives",
                    subtitle: "Raw values — no product meaning yet. Reference these from the Semantic layer."
                ) {
                    EmptyView()
                }

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ColorPrimitivesSection(document: document, undoManager: undoManager)
                        Divider().opacity(0.35)
                        SpacingPrimitivesSection(document: document, undoManager: undoManager)
                        Divider().opacity(0.35)
                        RadiusPrimitivesSection(document: document, undoManager: undoManager)
                        Divider().opacity(0.35)
                        TypographyPrimitivesSection(document: document, undoManager: undoManager)
                        Divider().opacity(0.35)
                        ElevationPrimitivesSection(document: document, undoManager: undoManager)
                        Divider().opacity(0.35)
                        StrokePrimitivesSection(document: document, undoManager: undoManager)
                        Divider().opacity(0.35)
                        MotionPrimitivesSection(document: document, undoManager: undoManager)
                        Spacer(minLength: 24)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .navigationTitle("Primitives")
    }
}

#Preview {
    PrimitivesPane(document: TokenforgeDocument())
        .frame(width: 880, height: 720)
}
