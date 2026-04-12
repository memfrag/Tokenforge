//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Normalizes Figma variable names into Tokenforge's kebab-case convention.
///
/// Algorithm:
/// 1. Insert a hyphen before any uppercase letter that follows a lowercase
///    letter. (`BackgroundPrimary` → `Background-Primary`)
/// 2. Lowercase the whole string.
/// 3. Replace runs of whitespace, underscores, periods, and slashes with
///    single hyphens.
/// 4. Collapse runs of `--` to `-`.
/// 5. Trim leading and trailing hyphens.
///
/// Examples:
/// - `White` → `white`
/// - `Small-Spacing` → `small-spacing`
/// - `BackgroundPrimary` → `background-primary`
/// - `Text` → `text`
/// - `Mode 1` → `mode-1`
///
nonisolated enum DTCGNameNormalizer {

    static func kebab(_ name: String) -> String {
        var withHyphens = ""
        var previousWasLowercase = false
        for character in name {
            if character.isUppercase, previousWasLowercase {
                withHyphens.append("-")
            }
            withHyphens.append(character)
            previousWasLowercase = character.isLowercase
        }

        var lowered = withHyphens.lowercased()

        // Replace whitespace / underscore / period / slash runs with hyphens.
        let separators: Set<Character> = [" ", "\t", "\n", "_", ".", "/", "\\"]
        var collapsed = ""
        var lastWasSeparator = false
        for character in lowered {
            if separators.contains(character) {
                if !lastWasSeparator {
                    collapsed.append("-")
                }
                lastWasSeparator = true
            } else {
                collapsed.append(character)
                lastWasSeparator = false
            }
        }
        lowered = collapsed

        // Collapse consecutive hyphens.
        while lowered.contains("--") {
            lowered = lowered.replacingOccurrences(of: "--", with: "-")
        }

        // Trim leading/trailing hyphens.
        while lowered.hasPrefix("-") {
            lowered.removeFirst()
        }
        while lowered.hasSuffix("-") {
            lowered.removeLast()
        }

        return lowered
    }
}
