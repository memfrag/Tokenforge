//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Emits a `DesignTokens.xcassets` directory containing one `.colorset` per
/// semantic color, each carrying a light and a dark hex value resolved from
/// the spec's primitive layer.
///
/// Return shape: a dictionary mapping relative paths (e.g.
/// `"DesignTokens.xcassets/actionPrimaryBg.colorset/Contents.json"`) to the
/// file's bytes. `ExportBundle` writes these all to disk atomically.
///
nonisolated enum AssetCatalogExporter {

    static let catalogDirectory = "DesignTokens.xcassets"

    static func export(_ spec: TokenforgeSpec, resolver: TokenResolver) -> [String: Data] {
        var files: [String: Data] = [:]

        files["\(catalogDirectory)/Contents.json"] = catalogRoot()

        for entry in spec.semantic.color {
            let identifier = IdentifierCase.camelCase(from: entry.name)
            let light = resolveHex(entry.light, appearance: .light, resolver: resolver)
            let dark = resolveHex(entry.dark, appearance: .dark, resolver: resolver)
            guard let light, let dark else {
                // An unresolved ref at this point is a bug — the export gate
                // should have blocked us earlier. Skip it defensively.
                continue
            }
            let colorset = colorsetContents(light: light, dark: dark)
            files["\(catalogDirectory)/\(identifier).colorset/Contents.json"] = colorset
        }

        return files
    }

    // MARK: - Helpers

    private static func resolveHex(_ ref: TokenRef, appearance: TokenResolver.Appearance, resolver: TokenResolver) -> String? {
        if case .color(let hex) = resolver.resolve(ref, appearance: appearance) {
            return hex
        }
        return nil
    }

    private static func catalogRoot() -> Data {
        let json = """
        {
          "info" : {
            "author" : "tokenforge",
            "version" : 1
          }
        }

        """
        return Data(json.utf8)
    }

    /// Emits the standard Xcode color-asset JSON with two appearances.
    /// Color space is sRGB, components are hex strings matching Xcode's
    /// on-disk format.
    private static func colorsetContents(light: String, dark: String) -> Data {
        let lightComponents = hexToComponentString(light)
        let darkComponents = hexToComponentString(dark)
        let json = """
        {
          "colors" : [
            {
              "color" : {
                "color-space" : "srgb",
                "components" : \(lightComponents)
              },
              "idiom" : "universal"
            },
            {
              "appearances" : [
                {
                  "appearance" : "luminosity",
                  "value" : "dark"
                }
              ],
              "color" : {
                "color-space" : "srgb",
                "components" : \(darkComponents)
              },
              "idiom" : "universal"
            }
          ],
          "info" : {
            "author" : "tokenforge",
            "version" : 1
          }
        }

        """
        return Data(json.utf8)
    }

    /// Converts `#RRGGBB` or `#RRGGBBAA` into the `{"red":..., "green":...,
    /// "blue":..., "alpha":...}` sub-object Xcode expects. Values are
    /// quoted hex strings like `"0xFF"`.
    private static func hexToComponentString(_ hex: String) -> String {
        var trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("#") {
            trimmed.removeFirst()
        }
        var red = 0
        var green = 0
        var blue = 0
        var alpha = 255
        if trimmed.count == 8, let value = UInt64(trimmed, radix: 16) {
            alpha = Int((value & 0xFF000000) >> 24)
            red = Int((value & 0x00FF0000) >> 16)
            green = Int((value & 0x0000FF00) >> 8)
            blue = Int(value & 0x000000FF)
        } else if trimmed.count == 6, let value = UInt64(trimmed, radix: 16) {
            red = Int((value & 0xFF0000) >> 16)
            green = Int((value & 0x00FF00) >> 8)
            blue = Int(value & 0x0000FF)
        }
        let alphaString = String(format: "%.3f", Double(alpha) / 255)
        return """
        {
                  "red" : "\(hexByte(red))",
                  "green" : "\(hexByte(green))",
                  "blue" : "\(hexByte(blue))",
                  "alpha" : "\(alphaString)"
                }
        """
    }

    private static func hexByte(_ value: Int) -> String {
        String(format: "0x%02X", value)
    }
}
