//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Author-added good/bad examples that get appended to Tokenforge's hardcoded
/// baseline when exporting the LLM contract.
nonisolated struct ExtraExamples: Codable, Equatable, Sendable {
    var items: [ExampleEntry]
}

nonisolated struct ExampleEntry: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var kind: ExampleKind
    /// Free-form YAML body describing the example screen or anti-pattern.
    var yaml: String
    /// Optional short description shown in the editor list.
    var caption: String

    init(id: UUID = UUID(), kind: ExampleKind, yaml: String, caption: String = "") {
        self.id = id
        self.kind = kind
        self.yaml = yaml
        self.caption = caption
    }
}

nonisolated enum ExampleKind: String, Codable, CaseIterable, Sendable {
    case good
    case bad
}
