//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct ContractPane: View {

    @Bindable var document: TokenforgeDocument

    @Environment(\.undoManager) private var undoManager

    var body: some View {
        Pane {
            VStack(spacing: 0) {
                PaneHeader(
                    title: "Contract & Export",
                    subtitle: "Author overrides for the LLM contract, document metadata, and export controls."
                ) {
                    EmptyView()
                }

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ContractExportSection(document: document)
                        Divider().opacity(0.35)
                        ContractMetaSection(document: document, undoManager: undoManager)
                        Divider().opacity(0.35)
                        ContractOverridesSection(document: document, undoManager: undoManager)
                        Divider().opacity(0.35)
                        ContractPreviewSection(document: document)
                        Spacer(minLength: 24)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .navigationTitle("Contract & Export")
    }
}

#Preview {
    ContractPane(document: TokenforgeDocument())
        .frame(width: 960, height: 720)
}
