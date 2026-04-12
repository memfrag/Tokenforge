//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// A reference to another token in the spec, written as `{primitives.color.blue-500}`.
///
/// Stored as a `String` on disk to preserve the author's literal path. Swift code should
/// wrap raw strings in `TokenRef` to gain access to parsing and validation helpers.
///
nonisolated struct TokenRef: Hashable, Codable, Sendable, RawRepresentable, CustomStringConvertible {

    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    var description: String { rawValue }

    /// Returns the dotted path inside the reference, or `nil` if the string is not a
    /// well-formed `{path.to.token}` reference.
    ///
    /// Example: `{primitives.color.blue-500}` → `["primitives", "color", "blue-500"]`.
    ///
    var path: [String]? {
        guard rawValue.hasPrefix("{"), rawValue.hasSuffix("}") else {
            return nil
        }
        let inner = rawValue.dropFirst().dropLast()
        guard !inner.isEmpty else {
            return nil
        }
        return inner.split(separator: ".").map(String.init)
    }

    /// Whether the raw string is shaped like a reference.
    var isReference: Bool { path != nil }

    /// Convenience constructor for a two-segment primitive reference like
    /// `{primitives.color.blue-500}`.
    static func primitive(_ category: String, _ name: String) -> TokenRef {
        TokenRef(rawValue: "{primitives.\(category).\(name)}")
    }

    /// Generic variadic builder for nested primitive paths such as
    /// `{primitives.typography.fontFamilies.base}` or
    /// `{primitives.motion.durations.quick}`.
    static func primitivePath(_ segments: String...) -> TokenRef {
        TokenRef(rawValue: "{primitives.\(segments.joined(separator: "."))}")
    }

    /// Convenience constructor for a two-segment semantic reference like
    /// `{semantic.color.background.primary}`. `name` may itself contain dots.
    static func semantic(_ category: String, _ name: String) -> TokenRef {
        TokenRef(rawValue: "{semantic.\(category).\(name)}")
    }
}
