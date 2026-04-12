//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Parses one Figma-flavored DTCG `.tokens.json` file into a `DTCGFile`.
///
/// Uses `JSONSerialization` rather than Codable because the file root is
/// a heterogeneous dictionary: each non-`$extensions` key is a token name
/// with a structured value, and the `$extensions` key carries metadata
/// (the mode name) on the same level. Codable's struct decoding doesn't
/// handle that shape ergonomically.
///
nonisolated enum DTCGParser {

    /// Parses raw JSON bytes into a `DTCGFile`. `filename` is used to
    /// derive the `collectionName` and to attribute warnings.
    static func parse(data: Data, filename: String) throws -> DTCGFile {
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            throw DTCGParseError.invalidJSON(filename: filename)
        }

        guard let root = object as? [String: Any] else {
            throw DTCGParseError.rootNotObject(filename: filename)
        }

        let modeName = extractModeName(from: root)
        let collectionName = collectionNameFromFilename(filename, modeName: modeName)

        var tokens: [DTCGToken] = []
        for (key, value) in root where key != "$extensions" {
            guard let tokenObject = value as? [String: Any] else {
                continue
            }
            if let token = parseToken(name: key, raw: tokenObject) {
                tokens.append(token)
            }
        }

        // Sort by name for stable ordering across re-imports.
        tokens.sort { $0.name < $1.name }

        return DTCGFile(
            collectionName: collectionName,
            modeName: modeName,
            sourceFilename: filename,
            tokens: tokens
        )
    }

    // MARK: - Token parsing

    private static func parseToken(name: String, raw: [String: Any]) -> DTCGToken? {
        let typeString = raw["$type"] as? String ?? "unsupported"
        let kind: DTCGType = DTCGType(rawValue: typeString) ?? .unsupported

        let literal = parseLiteral(value: raw["$value"], kind: kind)
        let aliasTargetName = parseAliasTargetName(extensions: raw["$extensions"])

        return DTCGToken(
            name: name,
            kind: kind,
            literal: literal,
            aliasTargetName: aliasTargetName
        )
    }

    private static func parseLiteral(value: Any?, kind: DTCGType) -> DTCGLiteral? {
        switch kind {
        case .color:
            // Figma color values are objects: { colorSpace, components, alpha, hex }.
            // The hex field is exactly what we want — fall back to building from
            // components if hex is somehow absent.
            if let object = value as? [String: Any] {
                if let hex = object["hex"] as? String, !hex.isEmpty {
                    return .color(hex: normalizeHex(hex))
                }
                if let components = object["components"] as? [Double] {
                    return .color(hex: hexFromComponents(components, alpha: object["alpha"] as? Double ?? 1))
                }
            }
            // Some standard DTCG files use `$value: "#RRGGBB"` directly.
            if let string = value as? String {
                return .color(hex: normalizeHex(string))
            }
            return nil
        case .number:
            if let number = value as? Double {
                return .number(number)
            }
            if let number = value as? Int {
                return .number(Double(number))
            }
            if let string = value as? String, let number = Double(string) {
                return .number(number)
            }
            return nil
        case .unsupported:
            return nil
        }
    }

    private static func parseAliasTargetName(extensions: Any?) -> String? {
        guard let extensions = extensions as? [String: Any],
              let aliasData = extensions["com.figma.aliasData"] as? [String: Any] else {
            return nil
        }
        return aliasData["targetVariableName"] as? String
    }

    // MARK: - Mode + collection extraction

    private static func extractModeName(from root: [String: Any]) -> String {
        guard let extensions = root["$extensions"] as? [String: Any],
              let mode = extensions["com.figma.modeName"] as? String else {
            return "Mode 1"
        }
        return mode
    }

    /// Strips `.tokens.json` and any trailing `.<Mode>` segment from the
    /// filename to recover the bare collection name.
    ///
    /// Examples:
    /// - `Primitives.tokens.json` → `Primitives`
    /// - `Semantic-Colors.Light-Mode.tokens.json` → `Semantic-Colors`
    /// - `Semantic-Spacing.tokens.json` → `Semantic-Spacing`
    ///
    private static func collectionNameFromFilename(_ filename: String, modeName: String) -> String {
        var name = (filename as NSString).lastPathComponent
        if name.hasSuffix(".tokens.json") {
            name = String(name.dropLast(".tokens.json".count))
        } else if name.hasSuffix(".json") {
            name = String(name.dropLast(".json".count))
        }
        // Strip trailing `.<Mode>` if present. The mode in the filename is
        // dash-encoded (e.g. `Light-Mode`); the in-file `modeName` uses
        // spaces (e.g. `Light Mode`). Convert the latter to the former for
        // matching.
        let dashedMode = modeName.replacingOccurrences(of: " ", with: "-")
        if name.hasSuffix(".\(dashedMode)") {
            name = String(name.dropLast(dashedMode.count + 1))
        }
        return name
    }

    // MARK: - Color helpers

    private static func normalizeHex(_ raw: String) -> String {
        var trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.hasPrefix("#") {
            trimmed = "#" + trimmed
        }
        return trimmed.uppercased()
    }

    /// Builds a `#RRGGBB` (or `#RRGGBBAA` if alpha < 1) string from a
    /// 3- or 4-element float component array on a 0..1 scale.
    private static func hexFromComponents(_ components: [Double], alpha: Double) -> String {
        guard components.count >= 3 else {
            return "#000000"
        }
        let red = Int((components[0] * 255).rounded())
        let green = Int((components[1] * 255).rounded())
        let blue = Int((components[2] * 255).rounded())
        if alpha < 1 {
            let alphaByte = Int((alpha * 255).rounded())
            return String(format: "#%02X%02X%02X%02X", red, green, blue, alphaByte)
        }
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
