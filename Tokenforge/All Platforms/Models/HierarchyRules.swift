//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Hierarchy layer — rules about how content competes for attention, plus the
/// emphasis scale that drives the Preview pane's debug overlay.
nonisolated struct HierarchyRules: Codable, Equatable, Sendable {

    /// Preferred top-level structure of a screen (e.g. topBar, primaryContent,
    /// secondaryContent, persistentAction).
    var screenStructure: [String]

    /// Maximum number of primary actions visible in the same local area.
    var maxPrimaryActionsPerArea: Int

    /// Free-text rules grouped by kind. Order is preserved.
    var rules: [HierarchyRule]

    /// 1–5 emphasis scale descriptions keyed by level.
    var emphasisScale: [EmphasisLevel]

    /// Mapping from a semantic type style name to its default emphasis level (1–5).
    /// Built-in sample screens inherit these defaults; per-element overrides can
    /// raise or lower an individual element's emphasis.
    var typeEmphasis: [TypeEmphasisMapping]
}

// MARK: - Rule

nonisolated struct HierarchyRule: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var kind: HierarchyRuleKind
    var text: String

    init(id: UUID = UUID(), kind: HierarchyRuleKind, text: String) {
        self.id = id
        self.kind = kind
        self.text = text
    }
}

/// Tag applied to a rule. Drives grouping in exported YAML and the Contract
/// markdown (`do`/`don't` lists).
nonisolated enum HierarchyRuleKind: String, Codable, CaseIterable, Sendable {
    case text
    case action
    case emphasis
    case `do`
    case dont
}

// MARK: - Emphasis

nonisolated struct EmphasisLevel: Codable, Equatable, Sendable, Identifiable {
    /// 1 = background/metadata, 5 = primary focal element.
    var level: Int
    var label: String

    var id: Int { level }
}

/// Links a semantic type style (e.g. `titleLarge`) to a default emphasis level.
nonisolated struct TypeEmphasisMapping: Codable, Equatable, Sendable, Identifiable {
    /// Reference into `semantic.type`.
    var typeStyle: TokenRef
    var level: Int

    var id: String { typeStyle.rawValue }
}
