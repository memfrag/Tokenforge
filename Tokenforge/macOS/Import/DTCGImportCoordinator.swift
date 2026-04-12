//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import AppKit

/// Orchestrates the File → Import DTCG Folder… flow:
///
/// 1. Show an `NSOpenPanel` configured as a directory picker.
/// 2. Enumerate the folder for `*.tokens.json` files (non-recursive).
/// 3. Run `DTCGImporter.importTokens(from:)`.
/// 4. Show a summary alert with primitive + semantic counts and any warnings.
/// 5. Apply the imported spec to the document via a single
///    `document.edit(...)` call so the import is one undo step.
///
/// Errors and warnings surface as `NSAlert` dialogs.
///
@MainActor
enum DTCGImportCoordinator {

    static func importIntoDocument(_ document: TokenforgeDocument, undoManager: UndoManager?) {
        // 1. Folder picker.
        let openPanel = NSOpenPanel()
        openPanel.title = "Import DTCG Tokens"
        openPanel.prompt = "Import"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = false

        guard openPanel.runModal() == .OK, let folderURL = openPanel.url else {
            return
        }

        // 2. Enumerate the folder for *.tokens.json files (non-recursive).
        let fileURLs = enumerateTokenFiles(in: folderURL)
        if fileURLs.isEmpty {
            presentNoFilesFound(folderURL: folderURL)
            return
        }

        // 3. Run the importer.
        let suggestedName = folderURL.lastPathComponent
        let result = DTCGImporter.importTokens(from: fileURLs, suggestedName: suggestedName)

        // 4. Apply atomically via document.edit so the import is one undo step.
        document.edit(actionName: "Import DTCG Tokens", undoManager: undoManager) { spec in
            spec = result.spec
        }

        // 5. Summary alert.
        presentImportSummary(result: result, fileCount: fileURLs.count)
    }

    // MARK: - File enumeration

    private static func enumerateTokenFiles(in folder: URL) -> [URL] {
        let manager = FileManager.default
        guard let contents = try? manager.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        return contents
            .filter { $0.lastPathComponent.lowercased().hasSuffix(".tokens.json") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    // MARK: - Alerts

    private static func presentNoFilesFound(folderURL: URL) {
        let alert = NSAlert()
        alert.messageText = "No DTCG token files found"
        alert.informativeText = "The folder \"\(folderURL.lastPathComponent)\" does not contain any *.tokens.json files. Pick a folder that holds the JSON files Figma's Variables export produced."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private static func presentImportSummary(result: DTCGImportResult, fileCount: Int) {
        let alert = NSAlert()
        alert.messageText = "Imported \(fileCount) DTCG file\(fileCount == 1 ? "" : "s")"

        var lines: [String] = []
        lines.append("\(result.primitiveColorCount) color primitive\(result.primitiveColorCount == 1 ? "" : "s")")
        lines.append("\(result.primitiveSpacingCount) spacing primitive\(result.primitiveSpacingCount == 1 ? "" : "s")")
        if result.primitiveRadiusCount > 0 {
            lines.append("\(result.primitiveRadiusCount) radius primitive\(result.primitiveRadiusCount == 1 ? "" : "s")")
        }
        lines.append("\(result.semanticColorCount) semantic color\(result.semanticColorCount == 1 ? "" : "s")")
        if result.semanticSpacingCount > 0 {
            lines.append("\(result.semanticSpacingCount) semantic spacing alias\(result.semanticSpacingCount == 1 ? "" : "es")")
        }
        if result.semanticRadiusCount > 0 {
            lines.append("\(result.semanticRadiusCount) semantic radius alias\(result.semanticRadiusCount == 1 ? "" : "es")")
        }

        var info = lines.joined(separator: " · ")
        info += "\n\nThe spec has been replaced. Component contracts use placeholder references that you'll need to wire to the imported tokens — see the Problems inspector."

        if !result.warnings.isEmpty {
            info += "\n\n\(result.warnings.count) warning\(result.warnings.count == 1 ? "" : "s"):\n"
            let listed = result.warnings.prefix(8).map { "• \($0)" }.joined(separator: "\n")
            info += listed
            if result.warnings.count > 8 {
                info += "\n… and \(result.warnings.count - 8) more."
            }
        }

        alert.informativeText = info
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
