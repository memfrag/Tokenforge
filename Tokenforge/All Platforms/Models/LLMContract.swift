//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Author's additions to the LLM contract. The base contract is **derived**
/// from the rest of the spec at export time; only overrides and project-specific
/// content live on disk.
///
nonisolated struct LLMContractOverrides: Codable, Equatable, Sendable {

    /// Natural-language role prompt prepended to the contract (e.g. "You are
    /// designing iOS screens using the attached design system.").
    var rolePrompt: String

    /// Extra hard rules the author wants appended to the derived base set.
    var extraHardRules: [String]

    /// Project-specific prose notes placed after the derived base in the
    /// exported markdown.
    var notes: String
}
