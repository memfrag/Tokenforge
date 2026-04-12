//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Helpers that build `PrimitiveReferencePicker.Candidate` arrays from the
/// document's semantic layer, for use in component editors. Component fields
/// conventionally reference semantic tokens (not primitives), so each helper
/// wraps the appropriate `spec.semantic.*` list.
///
enum ComponentCandidates {

    static func colors(_ spec: TokenforgeSpec) -> [PrimitiveReferencePicker.Candidate] {
        spec.semantic.color.map {
            PrimitiveReferencePicker.Candidate(name: $0.name, preview: .none)
        }
    }

    static func typeStyles(_ spec: TokenforgeSpec) -> [PrimitiveReferencePicker.Candidate] {
        spec.semantic.type.map {
            PrimitiveReferencePicker.Candidate(name: $0.name, preview: .none)
        }
    }

    static func spacingAliases(_ spec: TokenforgeSpec) -> [PrimitiveReferencePicker.Candidate] {
        spec.semantic.spacing.map {
            PrimitiveReferencePicker.Candidate(name: $0.name, preview: .none)
        }
    }

    static func radiusAliases(_ spec: TokenforgeSpec) -> [PrimitiveReferencePicker.Candidate] {
        spec.semantic.radius.map {
            PrimitiveReferencePicker.Candidate(name: $0.name, preview: .none)
        }
    }
}
