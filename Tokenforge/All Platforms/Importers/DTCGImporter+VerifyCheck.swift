//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import os

#if DEBUG

extension DTCGImporter {

    /// Launch-time assertion that the bundled DTCG example fixtures import
    /// into the expected `TokenforgeSpec` shape. Locks in the importer's
    /// contract with the user's hand-checked example so future edits can't
    /// silently break it.
    ///
    /// The four fixture files (`Primitives`, `Semantic-Colors.Light-Mode`,
    /// `Semantic-Colors.Dark-Mode`, `Semantic-Spacing`) ship as resources in
    /// the app bundle so the sandboxed app can read them. Release builds
    /// pay ~8KB for these — acceptable cost for a meaningful regression
    /// guard.
    ///
    static func verifyAgainstExampleFiles() {
        let logger = Logger(subsystem: "io.apparata.Tokenforge", category: "DTCGImporter")

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
            assertionFailure("Expected 4 DTCG fixture resources in app bundle, found \(files.count): \(files.map(\.lastPathComponent))")
            return
        }

        let result = DTCGImporter.importTokens(from: files, suggestedName: "DTCG Example")

        guard result.primitiveColorCount == 2 else {
            assertionFailure("DTCG verify: expected 2 color primitives, got \(result.primitiveColorCount)")
            return
        }
        guard result.primitiveSpacingCount == 3 else {
            assertionFailure("DTCG verify: expected 3 spacing primitives, got \(result.primitiveSpacingCount)")
            return
        }
        guard result.primitiveRadiusCount == 0 else {
            assertionFailure("DTCG verify: expected 0 radius primitives, got \(result.primitiveRadiusCount)")
            return
        }
        guard result.semanticColorCount == 1 else {
            assertionFailure("DTCG verify: expected 1 semantic color, got \(result.semanticColorCount)")
            return
        }
        guard result.semanticSpacingCount == 3 else {
            assertionFailure("DTCG verify: expected 3 semantic spacing aliases, got \(result.semanticSpacingCount)")
            return
        }
        guard result.semanticRadiusCount == 0 else {
            assertionFailure("DTCG verify: expected 0 semantic radius aliases, got \(result.semanticRadiusCount)")
            return
        }

        // Validate the single semantic color is `text` with light=black,
        // dark=white. This locks in the light/dark pairing logic specifically.
        guard let textColor = result.spec.semantic.color.first(where: { $0.name == "text" }) else {
            assertionFailure("DTCG verify: expected semantic color 'text' to exist")
            return
        }
        guard textColor.light.rawValue == "{primitives.color.black}" else {
            assertionFailure("DTCG verify: expected text.light to be black, got \(textColor.light.rawValue)")
            return
        }
        guard textColor.dark.rawValue == "{primitives.color.white}" else {
            assertionFailure("DTCG verify: expected text.dark to be white, got \(textColor.dark.rawValue)")
            return
        }

        logger.info("""
            DTCG fixtures verified: \
            \(result.primitiveColorCount, privacy: .public) colors, \
            \(result.primitiveSpacingCount, privacy: .public) spacings, \
            \(result.semanticColorCount, privacy: .public) semantic color(s), \
            \(result.semanticSpacingCount, privacy: .public) semantic spacings.
            """)
    }

}

#endif
