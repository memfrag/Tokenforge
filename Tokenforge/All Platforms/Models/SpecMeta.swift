//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Top-level metadata about a design system spec.
nonisolated struct SpecMeta: Codable, Equatable, Sendable {

    /// Human-readable name, shown in the window title and used as the export folder
    /// slug (e.g. `"Acme Design System"` → `Acme-Design-System-export`).
    var name: String

    /// Author-controlled semantic version of the design system itself, distinct from
    /// Tokenforge's own `SchemaVersion`.
    var version: String

    /// One-paragraph summary that seeds the LLM contract's natural-language preamble.
    var summary: String

    /// Author name, used in exports and the window footer.
    var author: String
}
