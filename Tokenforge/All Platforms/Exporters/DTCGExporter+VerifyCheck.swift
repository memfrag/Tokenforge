//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import os

#if DEBUG

extension DTCGExporter {

    /// Launch-time round-trip assertion: load the four bundled fixture
    /// files, import them via `DTCGImporter`, export the resulting spec
    /// via `DTCGExporter`, parse each emitted file via `DTCGParser`, then
    /// re-import. Assert the second spec's primitives + semantic layers
    /// match the first spec's.
    ///
    /// This is the gold-standard regression guard for the import/export
    /// pair: any drift in either side breaks the assertion.
    ///
    /// Note that we don't compare the *full* `TokenforgeSpec` because
    /// `meta.summary` is sourced from the importer's "Imported from DTCG"
    /// string and round-trips trivially. Component placeholders also
    /// depend on which primitives exist (the placeholder factory picks
    /// `first(of:)`), so we compare layers explicitly.
    ///
    static func verifyRoundTripAgainstExampleFiles() {
        let logger = Logger(subsystem: "io.apparata.Tokenforge", category: "DTCGExporter")

        let fixtureBaseNames = [
            "Primitives.tokens",
            "Semantic-Colors.Dark-Mode.tokens",
            "Semantic-Colors.Light-Mode.tokens",
            "Semantic-Spacing.tokens"
        ]

        let files = fixtureBaseNames.compactMap {
            Bundle.main.url(forResource: $0, withExtension: "json")
        }
        guard files.count == 4 else {
            assertionFailure("DTCG round-trip: missing fixture resources, found \(files.count)")
            return
        }

        // First import.
        let firstImport = DTCGImporter.importTokens(from: files, suggestedName: "DTCG Round-trip")
        let firstSpec = firstImport.spec

        // Export to in-memory file map.
        let emittedFiles = DTCGExporter.export(firstSpec)
        guard !emittedFiles.isEmpty else {
            assertionFailure("DTCG round-trip: exporter emitted zero files")
            return
        }

        // Re-parse each emitted file via the existing DTCGParser, then
        // re-import via DTCGImporter. We feed the parser by writing each
        // file to a temp directory because DTCGImporter.importTokens takes
        // file URLs, not in-memory data. Use the OS temp dir which the
        // sandbox always lets us write to.
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("tokenforge-dtcg-roundtrip-\(UUID().uuidString)", isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: tempRoot)
        }

        do {
            try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
            for (relativePath, data) in emittedFiles {
                let destination = tempRoot.appendingPathComponent(relativePath)
                try data.write(to: destination, options: [.atomic])
            }
        } catch {
            assertionFailure("DTCG round-trip: failed to stage temp files: \(error)")
            return
        }

        let stagedFiles = (try? FileManager.default.contentsOfDirectory(
            at: tempRoot,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []
        let stagedTokens = stagedFiles
            .filter { $0.lastPathComponent.lowercased().hasSuffix(".tokens.json") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        let secondImport = DTCGImporter.importTokens(from: stagedTokens, suggestedName: "DTCG Round-trip")
        let secondSpec = secondImport.spec

        // Layer-by-layer comparison.
        guard firstSpec.primitives.color == secondSpec.primitives.color else {
            assertionFailure("DTCG round-trip: color primitives drifted")
            return
        }
        guard firstSpec.primitives.spacing == secondSpec.primitives.spacing else {
            assertionFailure("DTCG round-trip: spacing primitives drifted")
            return
        }
        guard firstSpec.primitives.radius == secondSpec.primitives.radius else {
            assertionFailure("DTCG round-trip: radius primitives drifted")
            return
        }
        guard firstSpec.semantic.color == secondSpec.semantic.color else {
            assertionFailure("DTCG round-trip: semantic colors drifted")
            return
        }
        guard firstSpec.semantic.spacing == secondSpec.semantic.spacing else {
            assertionFailure("DTCG round-trip: semantic spacing aliases drifted")
            return
        }
        guard firstSpec.semantic.radius == secondSpec.semantic.radius else {
            assertionFailure("DTCG round-trip: semantic radius aliases drifted")
            return
        }

        logger.info("""
            DTCG round-trip verified: \
            \(firstImport.primitiveColorCount, privacy: .public) colors, \
            \(firstImport.primitiveSpacingCount, privacy: .public) spacings, \
            \(firstImport.semanticColorCount, privacy: .public) semantic color(s), \
            \(firstImport.semanticSpacingCount, privacy: .public) semantic spacings, \
            \(emittedFiles.count, privacy: .public) emitted files.
            """)
    }
}

#endif
