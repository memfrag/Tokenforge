//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import os

#if DEBUG

extension TokenforgeSpec {

    /// Loads `DefaultSpec.json` from the main bundle, decodes it, re-encodes it
    /// as pretty-printed JSON, decodes it again, and asserts the two decoded
    /// values are equal.
    ///
    /// Runs at app launch in `DEBUG` builds. If anything is off — missing
    /// resource, Codable mismatch, schema drift — Tokenforge crashes fast with
    /// a descriptive message rather than silently loading a broken spec.
    ///
    static func verifyDefaultSpecRoundTrip() {
        let logger = Logger(subsystem: "io.apparata.Tokenforge", category: "RoundTrip")
        do {
            let first = try loadDefaultFromBundle()
            let encoded = try first.encodeJSON()
            let second = try decode(from: encoded)

            guard first == second else {
                assertionFailure("DefaultSpec.json round-trip produced a different value after re-encoding.")
                return
            }

            // Spot-check a few known primitives and a two-hop semantic chain so the
            // resolver stays exercised alongside raw Codable.
            let resolver = TokenResolver(spec: first)
            let blue500 = resolver.resolve(TokenRef(rawValue: "{primitives.color.blue-500}"))
            let bgPrimaryLight = resolver.resolve(TokenRef(rawValue: "{semantic.color.background.primary}"), appearance: .light)
            let bgPrimaryDark = resolver.resolve(TokenRef(rawValue: "{semantic.color.background.primary}"), appearance: .dark)

            guard blue500 == .color(hex: "#2F6BFF") else {
                assertionFailure("TokenResolver failed to resolve blue-500.")
                return
            }
            guard bgPrimaryLight == .color(hex: "#FFFFFF"), bgPrimaryDark == .color(hex: "#111827") else {
                assertionFailure("TokenResolver failed to resolve semantic.color.background.primary for both appearances.")
                return
            }

            logger.info("DefaultSpec round-trip + resolver spot check passed (\(encoded.count, privacy: .public) bytes).")
        } catch {
            assertionFailure("DefaultSpec.json round-trip failed: \(error)")
        }
    }
}

#endif
