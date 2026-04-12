//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import AppKit

extension ExportCoordinator {

    /// Orchestrates the File → Export DTCG Folder… flow:
    ///
    /// 1. Run the validation gate (errors AND warnings block, same as
    ///    Export All).
    /// 2. Show an `NSOpenPanel` configured as a directory picker.
    /// 3. Compute `<picked>/<SpecName>-dtcg/`.
    /// 4. If that folder already exists, show an overwrite confirm.
    /// 5. Run `DTCGExporter.export(spec)` to build a `[String: Data]` map.
    /// 6. Write the map atomically via a sibling temp folder + move-into-place.
    /// 7. Reveal the final folder in Finder.
    ///
    /// Independent of the existing per-document export bookmark — DTCG and
    /// Tokenforge canonical exports may legitimately target different
    /// folders, and conflating them would surprise the author.
    ///
    static func exportDTCG(document: TokenforgeDocument) {
        let spec = document.spec

        // 1. Validation gate.
        let problems = Validator.validate(spec)
        if !problems.isEmpty {
            presentGateBlockedPublic(problems: problems)
            return
        }

        // 2. Folder picker.
        let openPanel = NSOpenPanel()
        openPanel.title = "Export DTCG Tokens"
        openPanel.prompt = "Export Here"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false
        guard openPanel.runModal() == .OK, let parentURL = openPanel.url else {
            return
        }

        // 3. Compute target subfolder.
        let subfolderName = dtcgFolderName(for: spec.meta.name)
        let targetURL = parentURL.appendingPathComponent(subfolderName, isDirectory: true)

        // 4. Overwrite confirm.
        if FileManager.default.fileExists(atPath: targetURL.path) {
            let alert = NSAlert()
            alert.messageText = "Replace existing DTCG export?"
            alert.informativeText = "A folder named \"\(targetURL.lastPathComponent)\" already exists at the chosen location. Replacing it will atomically overwrite the DTCG token files."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Replace")
            alert.addButton(withTitle: "Cancel")
            guard alert.runModal() == .alertFirstButtonReturn else {
                return
            }
        }

        // 5. Build the export map.
        let files = DTCGExporter.export(spec)
        guard !files.isEmpty else {
            let alert = NSAlert()
            alert.messageText = "Nothing to export"
            alert.informativeText = "The current spec contains no primitives or semantic tokens that the DTCG exporter knows how to emit."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        // 6. Atomic write via sibling temp folder.
        do {
            try writeFilesAtomically(files: files, target: targetURL)
        } catch {
            let alert = NSAlert()
            alert.messageText = "DTCG export failed"
            alert.informativeText = "\(error)"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        // 7. Reveal in Finder.
        NSWorkspace.shared.activateFileViewerSelecting([targetURL])
    }

    // MARK: - Slug

    static func dtcgFolderName(for specName: String) -> String {
        let trimmed = specName.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? "Untitled" : trimmed
        let replaced = base
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: " ", with: "-")
        return "\(replaced)-dtcg"
    }

    // MARK: - Atomic write

    private static func writeFilesAtomically(files: [String: Data], target: URL) throws {
        let parent = target.deletingLastPathComponent()
        let tempName = ".tokenforge-dtcg-\(UUID().uuidString)"
        let tempURL = parent.appendingPathComponent(tempName, isDirectory: true)

        let manager = FileManager.default
        try manager.createDirectory(at: tempURL, withIntermediateDirectories: true)

        do {
            for (relativePath, data) in files {
                let destination = tempURL.appendingPathComponent(relativePath)
                let parentDirectory = destination.deletingLastPathComponent()
                try manager.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
                try data.write(to: destination, options: [.atomic])
            }
            if manager.fileExists(atPath: target.path) {
                try manager.removeItem(at: target)
            }
            try manager.moveItem(at: tempURL, to: target)
        } catch {
            try? manager.removeItem(at: tempURL)
            throw error
        }
    }

    // MARK: - Bridging private gate dialog

    /// Re-uses the same gate-blocked dialog the canonical export shows.
    /// Wraps `presentGateBlocked` (private) by re-implementing the same
    /// content here, since Swift access control prevents calling the
    /// private overload from an extension in a separate file.
    private static func presentGateBlockedPublic(problems: [Problem]) {
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
}
