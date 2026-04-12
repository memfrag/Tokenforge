//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// A single validation finding produced by `Validator.validate(_:)`.
///
/// The `location` is coarse — it names the pane and a breadcrumb string
/// rather than a field-level selection ID. That's intentional for Phase 6:
/// click-to-navigate is deferred until the selection-routing work in a
/// later phase, and the breadcrumb is sufficient for the Problems list in
/// the inspector.
///
nonisolated struct Problem: Hashable, Identifiable, Sendable {

    enum Severity: String, Hashable, Sendable, Comparable {
        case error
        case warning

        static func < (lhs: Severity, rhs: Severity) -> Bool {
            // Errors sort before warnings.
            switch (lhs, rhs) {
            case (.error, .warning): return true
            case (.warning, .error): return false
            default: return false
            }
        }
    }

    enum Pane: String, Hashable, Sendable, CaseIterable {
        case primitives
        case semantic
        case hierarchy
        case components
        case contract
        case meta

        var label: String {
            switch self {
            case .primitives: return "Primitives"
            case .semantic: return "Semantic"
            case .hierarchy: return "Hierarchy"
            case .components: return "Components"
            case .contract: return "Contract & Export"
            case .meta: return "Meta"
            }
        }
    }

    /// Structural content of the problem. Identity is derived from this so
    /// repeated validation runs produce stable IDs (SwiftUI diffing stays
    /// happy when the list is re-computed every time the spec changes).
    var severity: Severity
    var pane: Pane
    var breadcrumb: String
    var title: String
    var detail: String?

    var id: Int {
        var hasher = Hasher()
        hasher.combine(severity)
        hasher.combine(pane)
        hasher.combine(breadcrumb)
        hasher.combine(title)
        hasher.combine(detail)
        return hasher.finalize()
    }
}

/// Summary counts used by the toolbar Problems chip and the inspector tab
/// badge.
nonisolated struct ProblemSummary: Hashable, Sendable {
    var errors: Int
    var warnings: Int

    var total: Int { errors + warnings }
    var isClean: Bool { total == 0 }

    static let empty = ProblemSummary(errors: 0, warnings: 0)

    init(problems: [Problem]) {
        self.errors = problems.filter { $0.severity == .error }.count
        self.warnings = problems.filter { $0.severity == .warning }.count
    }

    init(errors: Int, warnings: Int) {
        self.errors = errors
        self.warnings = warnings
    }
}
