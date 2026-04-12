//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Deterministic kebab-case → camelCase conversion used by the Swift exporter.
///
/// Examples:
/// - `"blue-500"` → `"blue500"`
/// - `"gray-700"` → `"gray700"`
/// - `"action.primary.bg"` → `"actionPrimaryBg"`
/// - `"background.primary"` → `"backgroundPrimary"`
///
/// Collisions — two distinct source names that collapse to the same
/// identifier — are reported by the collision detector so the exporter can
/// surface them as a blocking error before anything is written to disk.
///
nonisolated enum IdentifierCase {

    /// Converts a dotted-kebab name to a camelCase Swift identifier.
    static func camelCase(from name: String) -> String {
        let parts = name.split(whereSeparator: { $0 == "." || $0 == "-" })
        guard let first = parts.first else {
            return ""
        }
        let head = String(first).lowercased()
        let tail = parts.dropFirst().map { part -> String in
            let lower = String(part).lowercased()
            guard let firstChar = lower.first else {
                return ""
            }
            return firstChar.uppercased() + lower.dropFirst()
        }
        return head + tail.joined()
    }

    /// Returns an array of collision tuples — `(identifier, [sourceName...])`
    /// for every identifier that multiple source names collapse to.
    static func collisions(in names: [String]) -> [(identifier: String, sources: [String])] {
        var grouped: [String: [String]] = [:]
        for name in names {
            let id = camelCase(from: name)
            grouped[id, default: []].append(name)
        }
        return grouped
            .filter { $0.value.count > 1 }
            .map { ($0.key, $0.value.sorted()) }
            .sorted { $0.identifier < $1.identifier }
    }
}
