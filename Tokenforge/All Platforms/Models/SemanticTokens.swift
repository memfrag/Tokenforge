//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Semantic tokens layer — aliases on top of primitives.
///
/// Colors are **dual-referenced**: each `SemanticColor` stores one `TokenRef` for the
/// light appearance and one for the dark appearance, both required. Other categories
/// (type, spacing, radius) are single-value since they don't vary with appearance.
///
nonisolated struct SemanticTokens: Codable, Equatable, Sendable {

    var color: [SemanticColor]
    var type: [SemanticTextStyle]
    var spacing: [SemanticAlias]
    var radius: [SemanticAlias]
}

// MARK: - Color

nonisolated struct SemanticColor: Codable, Equatable, Sendable, Identifiable {
    var name: String
    /// Reference into `primitives.color` used when the app renders in the light appearance.
    var light: TokenRef
    /// Reference into `primitives.color` used when the app renders in the dark appearance.
    var dark: TokenRef

    var id: String { name }
}

// MARK: - Text style (composed typography)

/// A named composed text style that references primitives for family, size,
/// weight, and line height. This is the layer the product UI actually consumes.
nonisolated struct SemanticTextStyle: Codable, Equatable, Sendable, Identifiable {
    var name: String
    var fontFamily: TokenRef
    var fontSize: TokenRef
    var fontWeight: TokenRef
    var lineHeight: TokenRef

    var id: String { name }
}

// MARK: - Single-value alias

/// Shared shape for semantic.spacing and semantic.radius. Each entry is a named
/// alias pointing at a single primitive.
nonisolated struct SemanticAlias: Codable, Equatable, Sendable, Identifiable {
    var name: String
    var reference: TokenRef

    var id: String { name }
}
