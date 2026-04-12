//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// A read-only view of the current spec from a sample screen's perspective.
///
/// Sample screens in the Preview pane don't touch `TokenforgeDocument`
/// directly — they read tokens through this struct, which is injected via
/// the `\.resolvedTokens` environment key. That decouples sample code from
/// the document API and makes it easy to substitute a fresh `ResolvedTokens`
/// when the appearance switches between light and dark.
///
/// Lookup methods return optionals. Sample views should render the
/// `Palette.magentaPlaceholder` color when a required token is missing so
/// the miss is immediately visible — the fail-loud behavior the Phase 1
/// spec called for.
///
struct ResolvedTokens: Equatable {

    let spec: TokenforgeSpec
    let appearance: TokenResolver.Appearance

    private var resolver: TokenResolver {
        TokenResolver(spec: spec)
    }

    // MARK: - Colors

    /// Looks up a semantic color by name and returns the resolved `Color`
    /// for the current appearance, or `nil` if unresolved.
    func color(_ name: String) -> Color? {
        let ref = TokenRef.semantic("color", name)
        guard case .color(let hex) = resolver.resolve(ref, appearance: appearance) else {
            return nil
        }
        return Color(hex: hex)
    }

    // MARK: - Spacing / radius

    /// Resolved semantic spacing in points.
    func spacing(_ name: String) -> CGFloat? {
        let ref = TokenRef.semantic("spacing", name)
        if case .points(let value) = resolver.resolve(ref) {
            return CGFloat(value)
        }
        return nil
    }

    /// Resolved semantic radius in points.
    func radius(_ name: String) -> CGFloat? {
        let ref = TokenRef.semantic("radius", name)
        if case .points(let value) = resolver.resolve(ref) {
            return CGFloat(value)
        }
        return nil
    }

    // MARK: - Typography

    /// Resolves a semantic text style to a SwiftUI `Font` and returns the
    /// effective point size alongside. Returns `nil` if the semantic entry
    /// or any of its primitive references can't be resolved.
    func textStyle(_ name: String) -> ResolvedTextStyle? {
        guard let entry = spec.semantic.type.first(where: { $0.name == name }) else {
            return nil
        }

        // Size
        guard let pointSize = primitiveValue(
            ref: entry.fontSize,
            in: spec.primitives.typography.fontSizes,
            path: \.points
        ) else {
            return nil
        }

        // Weight
        guard let cssWeight = primitiveValue(
            ref: entry.fontWeight,
            in: spec.primitives.typography.fontWeights,
            path: \.weight
        ) else {
            return nil
        }
        let weight = Self.fontWeight(for: cssWeight)

        // Family (optional — may be a system font)
        let family = primitiveValue(
            ref: entry.fontFamily,
            in: spec.primitives.typography.fontFamilies,
            path: \.family
        )

        // Line height (optional)
        let multiplier = primitiveValue(
            ref: entry.lineHeight,
            in: spec.primitives.typography.lineHeights,
            path: \.multiplier
        ) ?? 1.2

        let font: Font
        if let family, !family.isEmpty, family != "SF Pro" {
            font = Font.custom(family, size: pointSize).weight(weight)
        } else {
            font = Font.system(size: pointSize, weight: weight)
        }

        return ResolvedTextStyle(
            font: font,
            pointSize: pointSize,
            weight: weight,
            lineHeightMultiplier: multiplier
        )
    }

    // MARK: - Emphasis

    /// The emphasis level (1–5) associated with a semantic text style via
    /// `hierarchy.typeEmphasis`, or `nil` if no mapping exists.
    func emphasisLevel(for typeStyleName: String) -> Int? {
        let ref = TokenRef.semantic("type", typeStyleName)
        return spec.hierarchy.typeEmphasis
            .first(where: { $0.typeStyle == ref })?.level
    }

    // MARK: - Helpers

    private func primitiveValue<Primitive, Value>(
        ref: TokenRef,
        in collection: [Primitive],
        path: KeyPath<Primitive, Value>
    ) -> Value? where Primitive: Identifiable, Primitive.ID == String {
        guard let tail = ref.path?.last else {
            return nil
        }
        guard let match = collection.first(where: { $0.id == tail }) else {
            return nil
        }
        return match[keyPath: path]
    }

    private static func fontWeight(for cssWeight: Int) -> Font.Weight {
        switch cssWeight {
        case ..<200: return .ultraLight
        case 200..<300: return .thin
        case 300..<400: return .light
        case 400..<500: return .regular
        case 500..<600: return .medium
        case 600..<700: return .semibold
        case 700..<800: return .bold
        case 800..<900: return .heavy
        default: return .black
        }
    }
}

// MARK: - Supporting types

struct ResolvedTextStyle: Equatable {
    var font: Font
    var pointSize: CGFloat
    var weight: Font.Weight
    var lineHeightMultiplier: Double
}

// MARK: - Palette

/// Magenta placeholder used whenever a sample screen asks for a token that
/// can't be resolved. Fail-loud: the miss is immediately visible rather
/// than silently substituted with a neutral gray.
enum Palette {
    static let magentaPlaceholder = Color(red: 1, green: 0, blue: 1)
}

// MARK: - Environment key

private struct ResolvedTokensKey: EnvironmentKey {
    static let defaultValue: ResolvedTokens? = nil
}

extension EnvironmentValues {
    var resolvedTokens: ResolvedTokens? {
        get { self[ResolvedTokensKey.self] }
        set { self[ResolvedTokensKey.self] = newValue }
    }
}
