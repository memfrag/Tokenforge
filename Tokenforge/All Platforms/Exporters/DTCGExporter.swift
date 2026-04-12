//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Emits a folder of `*.tokens.json` files in the **Figma Variables flavor**
/// of DTCG. The output is a deliberate inverse of `DTCGImporter` — a spec
/// produced by importing those files and then exporting again should
/// produce structurally identical files.
///
/// Files emitted (only when their source layer is non-empty):
///
/// - `Primitives.tokens.json` — every literal color/spacing/radius primitive
///   in one collection. Mode `"Mode 1"`.
/// - `Semantic-Colors.Light-Mode.tokens.json` and
///   `Semantic-Colors.Dark-Mode.tokens.json` — one alias entry per
///   `SemanticColor` per mode. Both files are always written together when
///   `semantic.color` is non-empty.
/// - `Semantic-Spacing.tokens.json` — semantic spacing aliases.
/// - `Semantic-Radius.tokens.json` — semantic radius aliases.
///
/// Each token has the same shape `DTCGParser` already understands:
///
/// ```json
/// "<TokenName>": {
///   "$type": "color" | "number",
///   "$value": <literal>,
///   "$extensions": {
///     "com.figma.aliasData": { "targetVariableName": "...", … }
///   }
/// }
/// ```
///
/// Aliases carry the resolved literal value alongside the alias metadata,
/// matching Figma's exact export shape.
///
/// Out of scope for v1: typography / elevation / stroke / motion primitives
/// (DTCG's typography composite is not handled by the importer either, so
/// exporting it would be one-way), hierarchy / components / LLM contract
/// layers (these are not tokens). Authors who need these can use Tokenforge's
/// canonical Export All instead.
///
nonisolated enum DTCGExporter {

    static func export(_ spec: TokenforgeSpec) -> [String: Data] {
        var files: [String: Data] = [:]

        if let primitivesData = makePrimitivesFile(spec: spec) {
            files["Primitives.tokens.json"] = primitivesData
        }

        if !spec.semantic.color.isEmpty {
            let resolver = TokenResolver(spec: spec)
            files["Semantic-Colors.Light-Mode.tokens.json"] =
                makeSemanticColorFile(spec: spec, resolver: resolver, appearance: .light, mode: "Light Mode")
            files["Semantic-Colors.Dark-Mode.tokens.json"] =
                makeSemanticColorFile(spec: spec, resolver: resolver, appearance: .dark, mode: "Dark Mode")
        }

        if !spec.semantic.spacing.isEmpty {
            files["Semantic-Spacing.tokens.json"] =
                makeSemanticNumberFile(
                    aliases: spec.semantic.spacing,
                    resolver: TokenResolver(spec: spec),
                    primitiveCategory: "spacing",
                    mode: "Mode 1"
                )
        }

        if !spec.semantic.radius.isEmpty {
            files["Semantic-Radius.tokens.json"] =
                makeSemanticNumberFile(
                    aliases: spec.semantic.radius,
                    resolver: TokenResolver(spec: spec),
                    primitiveCategory: "radius",
                    mode: "Mode 1"
                )
        }

        return files
    }

    // MARK: - Primitives

    private static func makePrimitivesFile(spec: TokenforgeSpec) -> Data? {
        if spec.primitives.color.isEmpty
            && spec.primitives.spacing.isEmpty
            && spec.primitives.radius.isEmpty {
            return nil
        }

        var root: [String: Any] = [:]
        for primitive in spec.primitives.color {
            root[primitive.name] = colorTokenObject(hex: primitive.hex, alias: nil)
        }
        for primitive in spec.primitives.spacing {
            root[primitive.name] = numberTokenObject(value: primitive.points, alias: nil)
        }
        for primitive in spec.primitives.radius {
            root[primitive.name] = numberTokenObject(value: primitive.points, alias: nil)
        }
        root["$extensions"] = ["com.figma.modeName": "Mode 1"]

        return serialize(root)
    }

    // MARK: - Semantic colors (one file per mode)

    private static func makeSemanticColorFile(
        spec: TokenforgeSpec,
        resolver: TokenResolver,
        appearance: TokenResolver.Appearance,
        mode: String
    ) -> Data {
        var root: [String: Any] = [:]
        for entry in spec.semantic.color {
            let ref = appearance == .light ? entry.light : entry.dark
            let resolvedHex: String
            if case .color(let hex) = resolver.resolve(ref, appearance: appearance) {
                resolvedHex = hex
            } else {
                resolvedHex = "#000000"
            }
            let aliasName = ref.path?.last ?? ""
            root[entry.name] = colorTokenObject(hex: resolvedHex, alias: aliasName)
        }
        root["$extensions"] = ["com.figma.modeName": mode]

        return serialize(root)
    }

    // MARK: - Semantic numbers (spacing / radius)

    private static func makeSemanticNumberFile(
        aliases: [SemanticAlias],
        resolver: TokenResolver,
        primitiveCategory: String,
        mode: String
    ) -> Data {
        var root: [String: Any] = [:]
        for alias in aliases {
            let resolvedNumber: Double
            if case .points(let value) = resolver.resolve(alias.reference) {
                resolvedNumber = value
            } else {
                resolvedNumber = 0
            }
            let aliasName = alias.reference.path?.last ?? ""
            root[alias.name] = numberTokenObject(value: resolvedNumber, alias: aliasName)
        }
        root["$extensions"] = ["com.figma.modeName": mode]

        return serialize(root)
    }

    // MARK: - Token-object builders

    private static func colorTokenObject(hex: String, alias: String?) -> [String: Any] {
        let value = colorValueObject(hex: hex)
        var extensions: [String: Any] = [:]
        if let alias, !alias.isEmpty {
            extensions["com.figma.aliasData"] = [
                "targetVariableName": alias
            ]
        }
        var token: [String: Any] = [
            "$type": "color",
            "$value": value
        ]
        if !extensions.isEmpty {
            token["$extensions"] = extensions
        }
        return token
    }

    private static func numberTokenObject(value: Double, alias: String?) -> [String: Any] {
        var extensions: [String: Any] = [:]
        if let alias, !alias.isEmpty {
            extensions["com.figma.aliasData"] = [
                "targetVariableName": alias
            ]
        }
        var token: [String: Any] = [
            "$type": "number",
            "$value": value
        ]
        if !extensions.isEmpty {
            token["$extensions"] = extensions
        }
        return token
    }

    private static func colorValueObject(hex: String) -> [String: Any] {
        let normalized = normalizeHex(hex)
        let (red, green, blue, alpha) = components(from: normalized)
        return [
            "colorSpace": "srgb",
            "components": [red, green, blue],
            "alpha": alpha,
            "hex": normalized
        ]
    }

    // MARK: - Hex helpers

    private static func normalizeHex(_ raw: String) -> String {
        var trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.hasPrefix("#") {
            trimmed = "#" + trimmed
        }
        return trimmed.uppercased()
    }

    /// Parses `#RRGGBB` or `#RRGGBBAA` into 0..1 floats.
    private static func components(from hex: String) -> (red: Double, green: Double, blue: Double, alpha: Double) {
        var stripped = hex
        if stripped.hasPrefix("#") {
            stripped.removeFirst()
        }
        guard stripped.count == 6 || stripped.count == 8,
              let value = UInt64(stripped, radix: 16) else {
            return (0, 0, 0, 1)
        }
        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double
        if stripped.count == 8 {
            red = Double((value & 0xFF000000) >> 24) / 255
            green = Double((value & 0x00FF0000) >> 16) / 255
            blue = Double((value & 0x0000FF00) >> 8) / 255
            alpha = Double(value & 0x000000FF) / 255
        } else {
            red = Double((value & 0xFF0000) >> 16) / 255
            green = Double((value & 0x00FF00) >> 8) / 255
            blue = Double(value & 0x0000FF) / 255
            alpha = 1
        }
        return (red, green, blue, alpha)
    }

    // MARK: - JSON serialization

    private static func serialize(_ object: [String: Any]) -> Data {
        let options: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys]
        do {
            return try JSONSerialization.data(withJSONObject: object, options: options)
        } catch {
            return Data()
        }
    }
}
