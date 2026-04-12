//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Tokenforge nudges authors toward kebab-case identifiers, matching the
/// convention in `docs/ios_design_system_for_llm.md`. This helper is used
/// to flag lint warnings in editor rows; it does not block editing.
///
/// A valid identifier is a non-empty sequence of one or more **segments**
/// separated by single dots. Each segment must:
/// - start with a lowercase letter
/// - contain only lowercase letters, digits, and single hyphens
/// - not start or end with a hyphen
/// - not contain consecutive hyphens
///
/// Primitive names are usually single-segment (`blue-500`). Semantic names
/// are often multi-segment and namespaced (`background.primary`,
/// `action.primary.bg`).
///
nonisolated enum KebabCase {

    static func isValid(_ name: String) -> Bool {
        guard !name.isEmpty else {
            return false
        }
        let segments = name.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        for segment in segments where !isValidSegment(segment) {
            return false
        }
        return true
    }

    private static func isValidSegment(_ segment: String) -> Bool {
        guard !segment.isEmpty else {
            return false
        }
        guard let first = segment.first, first.isLowercase, first.isLetter else {
            return false
        }
        if segment.hasSuffix("-") {
            return false
        }
        if segment.contains("--") {
            return false
        }
        for char in segment where !(char.isLowercase && char.isLetter) && !char.isNumber && char != "-" {
            return false
        }
        return true
    }
}
