//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Raw values — no product meaning yet. Every value in the Semantic layer
/// resolves to one or more primitives.
///
/// Each category is an ordered array of named structs (not a dictionary) so the
/// author's preferred ordering survives round-trips.
///
nonisolated struct Primitives: Codable, Equatable, Sendable {

    var color: [ColorPrimitive]
    var spacing: [SpacingPrimitive]
    var radius: [RadiusPrimitive]
    var typography: TypographyPrimitives
    var elevation: [ElevationPrimitive]
    var stroke: [StrokePrimitive]
    var motion: MotionPrimitives
}

// MARK: - Color

nonisolated struct ColorPrimitive: Codable, Equatable, Sendable, Identifiable {
    var name: String
    var hex: String

    var id: String { name }
}

// MARK: - Spacing

nonisolated struct SpacingPrimitive: Codable, Equatable, Sendable, Identifiable {
    var name: String
    var points: Double

    var id: String { name }
}

// MARK: - Radius

nonisolated struct RadiusPrimitive: Codable, Equatable, Sendable, Identifiable {
    var name: String
    var points: Double

    var id: String { name }
}

// MARK: - Typography

/// Typography primitives are structured into three nested tables because they
/// read more naturally grouped than as a flat list (font families are strings,
/// sizes and weights are numeric ladders).
nonisolated struct TypographyPrimitives: Codable, Equatable, Sendable {
    var fontFamilies: [FontFamilyPrimitive]
    var fontSizes: [FontSizePrimitive]
    var fontWeights: [FontWeightPrimitive]
    var lineHeights: [LineHeightPrimitive]
}

nonisolated struct FontFamilyPrimitive: Codable, Equatable, Sendable, Identifiable {
    var name: String
    /// PostScript name or family name understood by `Font(name:size:)`.
    var family: String
    /// If `true`, indicates a custom font file dropped into `Assets/Fonts/` of the bundle.
    var isCustom: Bool

    var id: String { name }
}

nonisolated struct FontSizePrimitive: Codable, Equatable, Sendable, Identifiable {
    var name: String
    var points: Double

    var id: String { name }
}

nonisolated struct FontWeightPrimitive: Codable, Equatable, Sendable, Identifiable {
    var name: String
    /// CSS-style weight (100–900). Maps to `Font.Weight` via a table.
    var weight: Int

    var id: String { name }
}

nonisolated struct LineHeightPrimitive: Codable, Equatable, Sendable, Identifiable {
    var name: String
    /// Multiplier of the font size. 1.4 = 140%.
    var multiplier: Double

    var id: String { name }
}

// MARK: - Elevation

nonisolated struct ElevationPrimitive: Codable, Equatable, Sendable, Identifiable {
    var name: String
    var offsetY: Double
    var blur: Double
    var opacity: Double

    var id: String { name }
}

// MARK: - Stroke

nonisolated struct StrokePrimitive: Codable, Equatable, Sendable, Identifiable {
    var name: String
    var width: Double

    var id: String { name }
}

// MARK: - Motion

nonisolated struct MotionPrimitives: Codable, Equatable, Sendable {
    var durations: [DurationPrimitive]
    var curves: [CurvePrimitive]
}

nonisolated struct DurationPrimitive: Codable, Equatable, Sendable, Identifiable {
    var name: String
    /// Milliseconds.
    var milliseconds: Int

    var id: String { name }
}

nonisolated struct CurvePrimitive: Codable, Equatable, Sendable, Identifiable {
    var name: String
    /// Cubic bezier control points (x1, y1, x2, y2).
    var x1: Double
    var y1: Double
    var x2: Double
    var y2: Double

    var id: String { name }
}
