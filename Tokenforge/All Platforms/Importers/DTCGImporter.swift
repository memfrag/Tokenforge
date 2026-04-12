//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Result of a DTCG import run. The `spec` is ready to assign directly to
/// a `TokenforgeDocument.spec`. `warnings` is a list of human-readable
/// advisories — skipped tokens, unrouted numbers, parser failures, etc. —
/// that the import coordinator surfaces in a summary alert.
nonisolated struct DTCGImportResult: Equatable, Sendable {
    var spec: TokenforgeSpec
    var warnings: [String]
    var primitiveColorCount: Int
    var primitiveSpacingCount: Int
    var primitiveRadiusCount: Int
    var semanticColorCount: Int
    var semanticSpacingCount: Int
    var semanticRadiusCount: Int
}

/// Orchestrates a DTCG import: parses each file, groups by collection,
/// builds primitives + semantic entries, and assembles a fresh
/// `TokenforgeSpec` shell with a placeholder `ComponentSet`.
///
/// Five passes:
/// 1. Parse all files (collect parse errors as warnings).
/// 2. Group by collection name.
/// 3. Collect literal tokens → primitives.
/// 4. Build the spacing/radius reference graph from aliasing tokens.
/// 5. Route number primitives to spacing or radius using the graph.
/// 6. Build semantic entries (paired light/dark for colors).
/// 7. Assemble the final spec with a placeholder `ComponentSet`.
///
nonisolated enum DTCGImporter {

    static func importTokens(
        from files: [URL],
        suggestedName: String = "Imported Design System"
    ) -> DTCGImportResult {
        var warnings: [String] = []

        // 1. Parse files.
        let parsed = parseAll(files: files, warnings: &warnings)

        // 2. Group by collection.
        let collections = Dictionary(grouping: parsed, by: { $0.collectionName })

        // 3. Collect literal tokens → primitives.
        var colorPrimitives: [ColorPrimitive] = []
        var seenColorNames = Set<String>()
        var numberPrimitiveDrafts: [(name: String, points: Double)] = []
        var seenNumberNames = Set<String>()

        for file in parsed {
            for token in file.tokens where token.aliasTargetName == nil {
                guard let literal = token.literal else {
                    if token.kind == .unsupported {
                        warnings.append("Skipped \(token.name) ($type unsupported in \(file.sourceFilename))")
                    }
                    continue
                }
                let kebabName = DTCGNameNormalizer.kebab(token.name)
                guard !kebabName.isEmpty else {
                    warnings.append("Skipped token with empty normalized name in \(file.sourceFilename)")
                    continue
                }
                switch literal {
                case .color(let hex):
                    if seenColorNames.insert(kebabName).inserted {
                        colorPrimitives.append(ColorPrimitive(name: kebabName, hex: hex))
                    } else {
                        warnings.append("Duplicate color primitive '\(kebabName)' (from \(file.sourceFilename)) — keeping first")
                    }
                case .number(let value):
                    if seenNumberNames.insert(kebabName).inserted {
                        numberPrimitiveDrafts.append((kebabName, value))
                    } else {
                        warnings.append("Duplicate number primitive '\(kebabName)' (from \(file.sourceFilename)) — keeping first")
                    }
                }
            }
        }

        // 4. Build the spacing/radius reference graph.
        var referencedBySpacing: Set<String> = []
        var referencedByRadius: Set<String> = []
        for file in parsed {
            let flavor = numberFlavor(forCollection: file.collectionName)
            for token in file.tokens
            where token.kind == .number && token.aliasTargetName != nil {
                guard let target = token.aliasTargetName else {
                    continue
                }
                let kebabTarget = DTCGNameNormalizer.kebab(target)
                switch flavor {
                case .spacing:
                    referencedBySpacing.insert(kebabTarget)
                case .radius:
                    referencedByRadius.insert(kebabTarget)
                case .unknown:
                    break
                }
            }
        }

        // 5. Route number primitives.
        var spacingPrimitives: [SpacingPrimitive] = []
        var radiusPrimitives: [RadiusPrimitive] = []
        for draft in numberPrimitiveDrafts {
            let inSpacing = referencedBySpacing.contains(draft.name)
            let inRadius = referencedByRadius.contains(draft.name)
            switch (inSpacing, inRadius) {
            case (true, false):
                spacingPrimitives.append(SpacingPrimitive(name: draft.name, points: draft.points))
            case (false, true):
                radiusPrimitives.append(RadiusPrimitive(name: draft.name, points: draft.points))
            case (true, true):
                spacingPrimitives.append(SpacingPrimitive(name: draft.name, points: draft.points))
                warnings.append("Number primitive '\(draft.name)' is referenced by both spacing and radius semantics — routed to spacing")
            case (false, false):
                spacingPrimitives.append(SpacingPrimitive(name: draft.name, points: draft.points))
                if !numberPrimitiveDrafts.isEmpty && referencedBySpacing.isEmpty && referencedByRadius.isEmpty {
                    // No semantic reference at all — silent default to spacing.
                } else {
                    warnings.append("Number primitive '\(draft.name)' is not referenced by any semantic file — defaulted to spacing")
                }
            }
        }

        // 6. Build semantic entries.
        let semanticColors = buildSemanticColors(
            collections: collections,
            warnings: &warnings
        )
        let (semanticSpacings, semanticRadii) = buildSemanticNumbers(
            parsed: parsed,
            warnings: &warnings
        )

        // 7. Assemble final spec.
        let placeholderColor = colorPrimitives.first.map { TokenRef.primitive("color", $0.name) }
            ?? TokenRef(rawValue: "{primitives.color.placeholder}")
        let placeholderSpacing: TokenRef
        if let first = semanticSpacings.first {
            placeholderSpacing = TokenRef.semantic("spacing", first.name)
        } else if let first = spacingPrimitives.first {
            placeholderSpacing = TokenRef.primitive("spacing", first.name)
        } else {
            placeholderSpacing = TokenRef(rawValue: "{semantic.spacing.placeholder}")
        }
        let placeholderRadius: TokenRef
        if let first = semanticRadii.first {
            placeholderRadius = TokenRef.semantic("radius", first.name)
        } else if let first = radiusPrimitives.first {
            placeholderRadius = TokenRef.primitive("radius", first.name)
        } else {
            placeholderRadius = TokenRef(rawValue: "{semantic.radius.placeholder}")
        }
        let placeholderTextStyle = TokenRef(rawValue: "{semantic.type.placeholder}")

        let spec = TokenforgeSpec(
            schemaVersion: SchemaVersion.current,
            meta: SpecMeta(
                name: suggestedName,
                version: "0.1.0",
                summary: "Imported from DTCG.",
                author: ""
            ),
            primitives: Primitives(
                color: colorPrimitives,
                spacing: spacingPrimitives,
                radius: radiusPrimitives,
                typography: TypographyPrimitives(
                    fontFamilies: [],
                    fontSizes: [],
                    fontWeights: [],
                    lineHeights: []
                ),
                elevation: [],
                stroke: [],
                motion: MotionPrimitives(durations: [], curves: [])
            ),
            semantic: SemanticTokens(
                color: semanticColors,
                type: [],
                spacing: semanticSpacings,
                radius: semanticRadii
            ),
            hierarchy: HierarchyRules(
                screenStructure: [],
                maxPrimaryActionsPerArea: 1,
                rules: [],
                emphasisScale: [],
                typeEmphasis: []
            ),
            components: ComponentSet.placeholder(
                color: placeholderColor,
                spacing: placeholderSpacing,
                radius: placeholderRadius,
                textStyle: placeholderTextStyle
            ),
            accessibility: AccessibilityRules(
                minTapTargetPoints: 44,
                minContrast: "WCAG AA",
                dynamicTypeSupport: true,
                notes: []
            ),
            llmContract: LLMContractOverrides(
                rolePrompt: "",
                extraHardRules: [],
                notes: ""
            ),
            examples: ExtraExamples(items: []),
            lastExportBookmarkID: nil
        )

        return DTCGImportResult(
            spec: spec,
            warnings: warnings,
            primitiveColorCount: colorPrimitives.count,
            primitiveSpacingCount: spacingPrimitives.count,
            primitiveRadiusCount: radiusPrimitives.count,
            semanticColorCount: semanticColors.count,
            semanticSpacingCount: semanticSpacings.count,
            semanticRadiusCount: semanticRadii.count
        )
    }

    // MARK: - Pass 1: parse all

    private static func parseAll(files: [URL], warnings: inout [String]) -> [DTCGFile] {
        var result: [DTCGFile] = []
        for url in files {
            do {
                let data = try Data(contentsOf: url)
                let parsed = try DTCGParser.parse(data: data, filename: url.lastPathComponent)
                result.append(parsed)
            } catch {
                warnings.append("Failed to parse \(url.lastPathComponent): \(error)")
            }
        }
        return result
    }

    // MARK: - Pass 6a: semantic colors

    private static func buildSemanticColors(
        collections: [String: [DTCGFile]],
        warnings: inout [String]
    ) -> [SemanticColor] {
        var result: [SemanticColor] = []

        for (collectionName, files) in collections.sorted(by: { $0.key < $1.key }) {
            // We only build SemanticColor entries from files that contain
            // aliasing color tokens. Files with only literal colors are
            // already consumed as primitives.
            let aliasingFiles = files.filter { file in
                file.tokens.contains { $0.kind == .color && $0.aliasTargetName != nil }
            }
            guard !aliasingFiles.isEmpty else {
                continue
            }

            switch aliasingFiles.count {
            case 1:
                // Single-mode collection: one entry per token, light=dark.
                let file = aliasingFiles[0]
                for token in file.tokens
                where token.kind == .color && token.aliasTargetName != nil {
                    let kebabName = DTCGNameNormalizer.kebab(token.name)
                    let target = DTCGNameNormalizer.kebab(token.aliasTargetName ?? "")
                    let ref = TokenRef.primitive("color", target)
                    result.append(SemanticColor(name: kebabName, light: ref, dark: ref))
                }
            case 2:
                // Two-mode collection: pair tokens with the same name across both files.
                let (lightFile, darkFile) = identifyLightDark(files: aliasingFiles)
                let lightByName = colorAliasMap(in: lightFile)
                let darkByName = colorAliasMap(in: darkFile)
                let allNames = Set(lightByName.keys).union(darkByName.keys)
                for name in allNames.sorted() {
                    let kebabName = DTCGNameNormalizer.kebab(name)
                    let lightTarget = lightByName[name].map(DTCGNameNormalizer.kebab) ?? darkByName[name].map(DTCGNameNormalizer.kebab) ?? ""
                    let darkTarget = darkByName[name].map(DTCGNameNormalizer.kebab) ?? lightByName[name].map(DTCGNameNormalizer.kebab) ?? ""
                    result.append(
                        SemanticColor(
                            name: kebabName,
                            light: TokenRef.primitive("color", lightTarget),
                            dark: TokenRef.primitive("color", darkTarget)
                        )
                    )
                }
            default:
                warnings.append("Collection '\(collectionName)' has \(aliasingFiles.count) modes; only the first two are imported as light/dark")
                let first = aliasingFiles[0]
                let second = aliasingFiles[1]
                let pair = identifyLightDark(files: [first, second])
                let lightByName = colorAliasMap(in: pair.light)
                let darkByName = colorAliasMap(in: pair.dark)
                let allNames = Set(lightByName.keys).union(darkByName.keys)
                for name in allNames.sorted() {
                    let kebabName = DTCGNameNormalizer.kebab(name)
                    let lightTarget = lightByName[name].map(DTCGNameNormalizer.kebab) ?? ""
                    let darkTarget = darkByName[name].map(DTCGNameNormalizer.kebab) ?? lightTarget
                    result.append(
                        SemanticColor(
                            name: kebabName,
                            light: TokenRef.primitive("color", lightTarget),
                            dark: TokenRef.primitive("color", darkTarget)
                        )
                    )
                }
            }
        }

        return result
    }

    private static func colorAliasMap(in file: DTCGFile) -> [String: String] {
        var result: [String: String] = [:]
        for token in file.tokens
        where token.kind == .color && token.aliasTargetName != nil {
            result[token.name] = token.aliasTargetName
        }
        return result
    }

    private static func identifyLightDark(files: [DTCGFile]) -> (light: DTCGFile, dark: DTCGFile) {
        // Mode-name detection: case-insensitive `contains("light")` → light bucket,
        // `contains("dark")` → dark bucket. If neither matches, alphabetical order
        // picks the first as light.
        let sorted = files.sorted { $0.modeName < $1.modeName }
        if let light = files.first(where: { $0.modeName.lowercased().contains("light") }),
           let dark = files.first(where: { $0.modeName.lowercased().contains("dark") }) {
            return (light, dark)
        }
        return (sorted[0], sorted[1])
    }

    // MARK: - Pass 6b: semantic numbers

    private static func buildSemanticNumbers(
        parsed: [DTCGFile],
        warnings: inout [String]
    ) -> (spacings: [SemanticAlias], radii: [SemanticAlias]) {
        var spacings: [SemanticAlias] = []
        var radii: [SemanticAlias] = []

        for file in parsed {
            let flavor = numberFlavor(forCollection: file.collectionName)
            for token in file.tokens
            where token.kind == .number && token.aliasTargetName != nil {
                guard let target = token.aliasTargetName else {
                    continue
                }
                let kebabName = DTCGNameNormalizer.kebab(token.name)
                let kebabTarget = DTCGNameNormalizer.kebab(target)
                switch flavor {
                case .spacing:
                    spacings.append(
                        SemanticAlias(
                            name: kebabName,
                            reference: TokenRef.primitive("spacing", kebabTarget)
                        )
                    )
                case .radius:
                    radii.append(
                        SemanticAlias(
                            name: kebabName,
                            reference: TokenRef.primitive("radius", kebabTarget)
                        )
                    )
                case .unknown:
                    spacings.append(
                        SemanticAlias(
                            name: kebabName,
                            reference: TokenRef.primitive("spacing", kebabTarget)
                        )
                    )
                    warnings.append("Semantic alias '\(kebabName)' from '\(file.collectionName)' has ambiguous flavor — defaulted to spacing")
                }
            }
        }

        return (spacings, radii)
    }

    // MARK: - Number flavor heuristic

    private enum NumberFlavor {
        case spacing
        case radius
        case unknown
    }

    private static func numberFlavor(forCollection collectionName: String) -> NumberFlavor {
        let lower = collectionName.lowercased()
        let radiusKeywords = ["radius", "corner", "rounding"]
        let spacingKeywords = ["spacing", "padding", "gap", "inset"]
        if radiusKeywords.contains(where: { lower.contains($0) }) {
            return .radius
        }
        if spacingKeywords.contains(where: { lower.contains($0) }) {
            return .spacing
        }
        return .unknown
    }
}
