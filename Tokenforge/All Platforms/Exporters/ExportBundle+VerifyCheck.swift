//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import os

#if DEBUG

extension ExportBundle {

    /// At app launch in DEBUG, build an `ExportBundle` from a stripped-down
    /// copy of `DefaultSpec.json` and assert every expected file is present
    /// and non-empty.
    ///
    /// Input scrubbing: the default spec ships with a few unused primitives
    /// on purpose (so the Problems inspector has something to show on first
    /// launch). Those warnings are fine for the UI, but `ExportBundle.build`
    /// runs every exporter unconditionally and we want to check its happy
    /// path. This helper removes those warning-inducing primitives from an
    /// in-memory copy before running the exporters.
    ///
    static func verifyAgainstDefaultSpec() {
        let logger = Logger(subsystem: "io.apparata.Tokenforge", category: "ExportVerify")
        do {
            var spec = try TokenforgeSpec.loadDefaultFromBundle()
            // Strip primitives that aren't referenced from the seed so the
            // build path runs clean. (Keep the unused-primitive warnings in
            // the UI; we just don't want them in this verify pass.)
            let referenceScan = try referencesInSpec(spec)
            spec.primitives.color.removeAll { primitive in
                let ref = TokenRef.primitive("color", primitive.name).rawValue
                return !referenceScan.contains(ref)
            }

            let bundle = try ExportBundle.build(from: spec)

            let required = [
                FileName.designTokensJSON,
                FileName.componentSpecsYAML,
                FileName.hierarchyRulesYAML,
                FileName.llmContractMarkdown,
                FileName.swiftTokenMapping
            ]

            for path in required {
                guard let data = bundle.files[path], !data.isEmpty else {
                    assertionFailure("Export bundle missing or empty: \(path)")
                    return
                }
            }

            // Catalog must contain at least the root Contents.json and one colorset.
            let catalogRoot = "\(AssetCatalogExporter.catalogDirectory)/Contents.json"
            guard bundle.files[catalogRoot] != nil else {
                assertionFailure("Export bundle missing \(catalogRoot)")
                return
            }
            let colorsetCount = bundle.files.keys.filter {
                $0.hasSuffix(".colorset/Contents.json")
            }.count
            guard colorsetCount > 0 else {
                assertionFailure("Export bundle has no .colorset entries")
                return
            }

            logger.info("""
                Export bundle verified: \(bundle.files.count, privacy: .public) files, \
                \(colorsetCount, privacy: .public) colorsets.
                """)
        } catch {
            assertionFailure("ExportBundle verify failed: \(error)")
        }
    }

    /// Returns the set of every `"{...}"` reference string present in the
    /// JSON encoding of a spec. Mirrors `Validator.scanReferences` but we
    /// can't call that from here because it's a private type on the
    /// validator. Fine — this helper is DEBUG-only.
    private static func referencesInSpec(_ spec: TokenforgeSpec) throws -> Set<String> {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(spec)
        guard let text = String(data: data, encoding: .utf8) else {
            return []
        }
        var refs: Set<String> = []
        var index = text.startIndex
        while let openQuote = text[index...].firstIndex(of: "\"") {
            let afterQuote = text.index(after: openQuote)
            guard afterQuote < text.endIndex, text[afterQuote] == "{" else {
                index = afterQuote
                continue
            }
            guard let closeBrace = text[afterQuote...].firstIndex(of: "}") else {
                break
            }
            let afterBrace = text.index(after: closeBrace)
            guard afterBrace < text.endIndex, text[afterBrace] == "\"" else {
                index = afterBrace
                continue
            }
            refs.insert(String(text[afterQuote...closeBrace]))
            index = text.index(after: afterBrace)
        }
        return refs
    }
}

#endif
