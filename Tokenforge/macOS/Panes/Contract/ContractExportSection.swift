//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import AppKit

/// First section of the Contract & Export pane — three live action buttons
/// that mirror the File-menu items so the author can drive exports without
/// hunting through the menu bar.
///
/// All three actions go straight to the existing infrastructure:
/// - **Export All…** → `ExportCoordinator.exportAll(document:)`
/// - **Export DTCG Folder…** → `ExportCoordinator.exportDTCG(document:)`
/// - **Copy LLM Prompt** → `LLMContractExporter.export(document.spec)` →
///   `NSPasteboard.general`
///
struct ContractExportSection: View {

    let document: TokenforgeDocument

    var body: some View {
        SectionCard(title: "Export") {
            EmptyView()
        } content: {
            HStack(spacing: 10) {
                Button {
                    ExportCoordinator.exportAll(document: document)
                } label: {
                    Label("Export All…", systemImage: "square.and.arrow.up")
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("e", modifiers: [.shift, .command])

                Button {
                    ExportCoordinator.exportDTCG(document: document)
                } label: {
                    Label("Export DTCG Folder…", systemImage: "tray.and.arrow.up")
                }
                .controlSize(.large)
                .buttonStyle(.bordered)

                Button {
                    copyLLMPrompt()
                } label: {
                    Label("Copy LLM Prompt", systemImage: "doc.on.doc")
                }
                .controlSize(.large)
                .buttonStyle(.bordered)
                .keyboardShortcut("l", modifiers: [.option, .command])

                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        }
    }

    @MainActor
    private func copyLLMPrompt() {
        let data = LLMContractExporter.export(document.spec)
        guard let markdown = String(data: data, encoding: .utf8) else {
            return
        }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(markdown, forType: .string)
    }
}
