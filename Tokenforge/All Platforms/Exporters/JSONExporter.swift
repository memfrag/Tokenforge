//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Emits the canonical token dictionary as `design-tokens.json`.
///
/// Trivial wrapper around `TokenforgeSpec.encodeJSON()` that sorts the
/// top-level keys and pretty-prints so downstream consumers get a stable,
/// git-diffable file.
///
nonisolated enum JSONExporter {

    static func export(_ spec: TokenforgeSpec) throws -> Data {
        try spec.encodeJSON()
    }
}
