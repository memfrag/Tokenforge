//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// File menu items for importing tokens into a Tokenforge document.
///
/// Currently exposes a single command:
/// - **Import DTCG Folder…** (⌘⇧I) — runs the `DTCGImportCoordinator` flow:
///   folder picker → enumerate `*.tokens.json` files → parse → build a
///   fresh `TokenforgeSpec` → assign in one undo step.
///
/// The command requires a focused document to be enabled. Focus comes via
/// `@FocusedValue(\.tokenforgeDocument)`, mirroring the export commands
/// pattern in `ExportCommands.swift`.
///
struct ImportCommands: Commands {

    @FocusedValue(\.tokenforgeDocument) private var document

    var body: some Commands {
        CommandGroup(after: .importExport) {
            Button("Import DTCG Folder…") {
                guard let document else {
                    return
                }
                DTCGImportCoordinator.importIntoDocument(document, undoManager: nil)
            }
            .keyboardShortcut("i", modifiers: [.shift, .command])
            .disabled(document == nil)
        }
    }
}
