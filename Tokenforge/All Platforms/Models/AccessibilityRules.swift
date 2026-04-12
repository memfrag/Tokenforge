//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Accessibility constraints the LLM is told to honor.
nonisolated struct AccessibilityRules: Codable, Equatable, Sendable {

    /// Minimum interactive target size in points (Apple HIG default: 44).
    var minTapTargetPoints: Double

    /// WCAG contrast level (e.g. "AA", "AAA").
    var minContrast: String

    /// Whether the design system commits to supporting Dynamic Type.
    var dynamicTypeSupport: Bool

    /// Additional free-text notes that get copied verbatim into the LLM contract.
    var notes: [String]
}
