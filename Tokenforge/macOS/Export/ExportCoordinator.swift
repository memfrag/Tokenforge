//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import AppKit

/// Orchestrates the Export All… flow:
///
/// 1. Run `Validator` against the spec and abort if there are any problems.
/// 2. Show an `NSOpenPanel` configured as a directory picker.
/// 3. Compute `<picked>/<SpecName>-export/`.
/// 4. If that folder already exists, show an overwrite confirm.
/// 5. Build an `ExportBundle` and write it atomically.
/// 6. Reveal the final folder in Finder.
///
/// Errors surface as `NSAlert` dialogs. All file I/O flows through the
/// sandboxed `ENABLE_USER_SELECTED_FILES = readwrite` entitlement.
///
@MainActor
enum ExportCoordinator {

    static func exportAll(document: TokenforgeDocument) {
        let spec = document.spec

        // 1. Validation gate — block on any problem (errors OR warnings).
        let problems = Validator.validate(spec)
        if !problems.isEmpty {
            presentGateBlocked(problems: problems)
            return
        }

        // 2. Resolve or pick the parent folder.
        let parentURL: URL
        var usedBookmark = false
        if let bookmarkID = spec.lastExportBookmarkID,
           let resolved = ExportBookmarks.resolve(bookmarkID) {
            parentURL = resolved
            usedBookmark = true
        } else if let picked = runFolderPicker() {
            parentURL = picked
        } else {
            return
        }

        // Start scoping access if we got the URL from a stored bookmark.
        // Freshly-picked URLs from NSOpenPanel already carry temporary
        // scoped access for the duration of this process.
        let needsScopeStart = usedBookmark
        let accessed = needsScopeStart ? parentURL.startAccessingSecurityScopedResource() : false
        defer {
            if accessed {
                parentURL.stopAccessingSecurityScopedResource()
            }
        }

        // 3. Compute target subfolder.
        let subfolderName = exportFolderName(for: spec.meta.name)
        let targetURL = parentURL.appendingPathComponent(subfolderName, isDirectory: true)

        // 4. Overwrite confirm.
        if FileManager.default.fileExists(atPath: targetURL.path) {
            let shouldReplace = presentOverwriteConfirm(targetURL: targetURL)
            guard shouldReplace else {
                return
            }
        }

        // 5. Build and write.
        do {
            let bundle = try ExportBundle.build(from: spec)
            try bundle.write(to: targetURL)
        } catch {
            presentWriteFailed(error: error)
            return
        }

        // 6. On a successful fresh-picker export, mint a bookmark ID and
        //    store the security-scoped bookmark so the next export skips
        //    the picker.
        if !usedBookmark {
            let bookmarkID = spec.lastExportBookmarkID ?? UUID()
            if ExportBookmarks.storeBookmark(for: parentURL, id: bookmarkID) {
                document.spec.lastExportBookmarkID = bookmarkID
            }
        }

        // 7. Reveal in Finder.
        NSWorkspace.shared.activateFileViewerSelecting([targetURL])
    }

    private static func runFolderPicker() -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.title = "Export Design System"
        openPanel.prompt = "Export Here"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false
        guard openPanel.runModal() == .OK else {
            return nil
        }
        return openPanel.url
    }

    // MARK: - Slug

    /// Slugifies the spec name into a safe folder name. Replaces whitespace
    /// and path separators; otherwise preserves case.
    static func exportFolderName(for specName: String) -> String {
        let trimmed = specName.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? "Untitled" : trimmed
        let replaced = base
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: " ", with: "-")
        return "\(replaced)-export"
    }

    // MARK: - Dialogs

    private static func presentGateBlocked(problems: [Problem]) {
        let summary = ProblemSummary(problems: problems)
        let alert = NSAlert()
        alert.messageText = "Export blocked by validation problems"
        var info = "Tokenforge refuses to export while the spec has "
        var parts: [String] = []
        if summary.errors > 0 {
            parts.append("\(summary.errors) error\(summary.errors == 1 ? "" : "s")")
        }
        if summary.warnings > 0 {
            parts.append("\(summary.warnings) warning\(summary.warnings == 1 ? "" : "s")")
        }
        info += parts.joined(separator: " and ")
        info += ". Resolve all items in the Problems inspector and try again.\n\n"
        let listed = problems.prefix(6).map { problem -> String in
            let bullet = problem.severity == .error ? "●" : "▲"
            let detail = problem.detail.map { " — \($0)" } ?? ""
            return "\(bullet) \(problem.title)\(detail)"
        }
        info += listed.joined(separator: "\n")
        if problems.count > 6 {
            info += "\n… and \(problems.count - 6) more."
        }
        alert.informativeText = info
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private static func presentOverwriteConfirm(targetURL: URL) -> Bool {
        let alert = NSAlert()
        alert.messageText = "Replace existing export?"
        alert.informativeText = "A folder named \"\(targetURL.lastPathComponent)\" already exists at the chosen location. Replacing it will atomically overwrite all five export files and the DesignTokens.xcassets catalog."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Replace")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }

    private static func presentWriteFailed(error: Error) {
        let alert = NSAlert()
        alert.messageText = "Export failed"
        alert.informativeText = "\(error)"
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
