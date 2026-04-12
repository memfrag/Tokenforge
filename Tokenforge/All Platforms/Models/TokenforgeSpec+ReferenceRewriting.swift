//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

nonisolated extension TokenforgeSpec {

    /// Rewrites every `TokenRef` field in the spec that currently equals
    /// `oldRef` to instead equal `newRef`.
    ///
    /// Implemented via a JSON encode / string-replace / decode round-trip.
    /// This is safe because every `TokenRef` serializes to a quoted string of
    /// the form `"{path.to.token}"`, which is unambiguous — the surrounding
    /// quotes plus the `{...}` braces plus the full path make collisions with
    /// unrelated string fields effectively impossible for well-formed specs.
    ///
    /// Used by the Primitives and Semantic editors so renaming a token
    /// propagates to every reference site (other primitives, semantic
    /// entries, component contracts, hierarchy emphasis mappings, …) in a
    /// single mutation — and, because callers wrap this in
    /// `TokenforgeDocument.edit(...)`, in a single undo step.
    ///
    /// If the round-trip fails for any reason, the spec is left untouched and
    /// the caller's local name change still applies; stale references become
    /// validation errors in the Problems pane (Phase 6).
    ///
    mutating func rewriteAllReferences(from oldRef: TokenRef, to newRef: TokenRef) {
        guard oldRef != newRef, oldRef.isReference, newRef.isReference else {
            return
        }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            let data = try encoder.encode(self)
            guard var text = String(data: data, encoding: .utf8) else {
                return
            }
            let needle = "\"\(oldRef.rawValue)\""
            let replacement = "\"\(newRef.rawValue)\""
            text = text.replacingOccurrences(of: needle, with: replacement)
            guard let rewritten = text.data(using: .utf8) else {
                return
            }
            let decoder = JSONDecoder()
            self = try decoder.decode(TokenforgeSpec.self, from: rewritten)
        } catch {
            // Leave the spec unchanged; the caller's local name update still
            // applies. Stale references will show as Problems in Phase 6.
        }
    }
}
