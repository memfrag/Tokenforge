//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// In-memory collection of files produced by one Export All run.
///
/// Key is a path relative to the target subfolder
/// (e.g. `"design-tokens.json"`, `"DesignTokens.xcassets/Contents.json"`);
/// value is the file's bytes. `ExportBundle.write(to:)` writes the whole
/// map to disk atomically via a sibling temp folder.
///
nonisolated struct ExportBundle {

    /// Canonical filenames for the five primary deliverables. Matches
    /// §15 of `docs/ios_design_system_for_llm.md`.
    enum FileName {
        static let designTokensJSON = "design-tokens.json"
        static let componentSpecsYAML = "component-specs.yaml"
        static let hierarchyRulesYAML = "hierarchy-rules.yaml"
        static let llmContractMarkdown = "llm-design-contract.md"
        static let swiftTokenMapping = "swift-token-mapping.swift"
    }

    var files: [String: Data]

    /// Builds an `ExportBundle` from the spec. Runs every exporter; does no
    /// filesystem I/O. Throws only when a Swift-identifier collision blocks
    /// the Swift exporter (the validation gate in `ExportCoordinator`
    /// catches token problems earlier).
    static func build(from spec: TokenforgeSpec) throws -> ExportBundle {
        let resolver = TokenResolver(spec: spec)
        var files: [String: Data] = [:]

        files[FileName.designTokensJSON] = try JSONExporter.export(spec)
        files[FileName.componentSpecsYAML] = YAMLExporter.exportComponents(spec)
        files[FileName.hierarchyRulesYAML] = YAMLExporter.exportHierarchy(spec)
        files[FileName.llmContractMarkdown] = LLMContractExporter.export(spec)
        files[FileName.swiftTokenMapping] = try SwiftExporter.export(spec, resolver: resolver)

        let catalog = AssetCatalogExporter.export(spec, resolver: resolver)
        for (path, data) in catalog {
            files[path] = data
        }

        return ExportBundle(files: files)
    }

    /// Writes the bundle to `target`, which is the final `<SpecName>-export/`
    /// folder. Uses a sibling temp directory to stage the write, then
    /// swaps the temp into place so a crash or sandbox denial mid-write
    /// doesn't leave a half-populated export folder.
    func write(to target: URL) throws {
        let parent = target.deletingLastPathComponent()
        let tempName = ".tokenforge-export-\(UUID().uuidString)"
        let tempURL = parent.appendingPathComponent(tempName, isDirectory: true)

        let fileManager = FileManager.default
        try fileManager.createDirectory(at: tempURL, withIntermediateDirectories: true)

        do {
            for (relativePath, data) in files {
                let destination = tempURL.appendingPathComponent(relativePath)
                let parentDirectory = destination.deletingLastPathComponent()
                try fileManager.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
                try data.write(to: destination, options: [.atomic])
            }

            // Remove any existing target, then move the temp directory into place.
            if fileManager.fileExists(atPath: target.path) {
                try fileManager.removeItem(at: target)
            }
            try fileManager.moveItem(at: tempURL, to: target)
        } catch {
            // Clean up partial temp directory on failure, ignoring secondary errors.
            try? fileManager.removeItem(at: tempURL)
            throw error
        }
    }
}
