//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import AppKit

/// File → Export menu items for Tokenforge.
///
/// Both items require a focused document to be enabled. The focus value is
/// installed by `DocumentWindow` via `.focusedSceneValue(\.tokenforgeDocument)`,
/// so these commands are only active while a document window is key.
///
/// Menu layout:
/// - **Export All…** (⌘⇧E) — runs the validation gate, folder picker, and
///   writes the five canonical deliverables plus the asset catalog in one
///   atomic swap. Remembers the parent folder per document via a
///   security-scoped bookmark so the second and subsequent runs skip the
///   picker unless the remembered folder is no longer reachable.
/// - **Copy LLM Prompt** (⌥⌘L) — builds the `llm-design-contract.md`
///   markdown for the focused document and writes it to the clipboard. No
///   gate — useful even while the spec has warnings.
///
struct ExportCommands: Commands {

    @FocusedValue(\.tokenforgeDocument) private var document

    var body: some Commands {
        CommandGroup(replacing: .importExport) {
            Button("Export All…") {
                guard let document else {
                    return
                }
                ExportCoordinator.exportAll(document: document)
            }
            .keyboardShortcut("e", modifiers: [.shift, .command])
            .disabled(document == nil)

            Button("Export DTCG Folder…") {
                guard let document else {
                    return
                }
                ExportCoordinator.exportDTCG(document: document)
            }
            .disabled(document == nil)

            Button("Copy LLM Prompt") {
                guard let document else {
                    return
                }
                copyLLMPrompt(for: document)
            }
            .keyboardShortcut("l", modifiers: [.option, .command])
            .disabled(document == nil)
        }
    }

    // MARK: - Copy LLM Prompt

    @MainActor
    private func copyLLMPrompt(for document: TokenforgeDocument) {
        let data = LLMContractExporter.export(document.spec)
        guard let markdown = String(data: data, encoding: .utf8) else {
            return
        }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(markdown, forType: .string)
    }
}
