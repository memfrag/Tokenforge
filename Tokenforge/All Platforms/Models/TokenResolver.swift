//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Resolves `{path.to.token}` references against a `TokenforgeSpec`.
///
/// The resolver supports paths rooted at either `primitives.*` or `semantic.*`.
/// Semantic references transparently chase through the semantic layer down to a
/// concrete primitive value, so `{semantic.color.background.primary}` ultimately
/// yields a hex string.
///
/// This is a minimal Phase 2 implementation: it knows about colors, spacing, and
/// radius primitives, which is enough to verify round-trip semantics. Later
/// phases extend it to typography, elevation, stroke, and motion.
///
nonisolated struct TokenResolver {

    let spec: TokenforgeSpec

    // MARK: - Public API

    /// Returns `true` iff `ref` points at a token that actually exists in the
    /// current spec, regardless of whether the resolver can produce a
    /// structured `ResolvedValue` for it.
    ///
    /// Used by the validator so that typography/elevation/stroke/motion
    /// references — which don't currently produce structured resolved values
    /// — aren't falsely flagged as unresolved.
    ///
    func referenceExists(_ ref: TokenRef) -> Bool {
        guard let path = ref.path, path.count >= 3 else {
            return false
        }
        switch path[0] {
        case "primitives":
            return primitiveExists(category: path[1], tail: Array(path.dropFirst(2)))
        case "semantic":
            return semanticExists(category: path[1], tail: Array(path.dropFirst(2)))
        default:
            return false
        }
    }

    /// Resolves a reference to its concrete value. Returns `nil` if the
    /// reference is malformed or points at a missing token.
    ///
    /// - Parameters:
    ///   - ref: The reference to resolve.
    ///   - appearance: Which appearance to pick for semantic colors.
    func resolve(_ ref: TokenRef, appearance: Appearance = .light) -> ResolvedValue? {
        guard let path = ref.path, path.count >= 3 else {
            return nil
        }
        switch path[0] {
        case "primitives":
            return resolvePrimitive(category: path[1], name: path[2])
        case "semantic":
            return resolveSemantic(category: path[1], path: Array(path.dropFirst(2)), appearance: appearance)
        default:
            return nil
        }
    }

    // MARK: - Primitive resolution

    private func resolvePrimitive(category: String, name: String) -> ResolvedValue? {
        switch category {
        case "color":
            guard let prim = spec.primitives.color.first(where: { $0.name == name }) else {
                return nil
            }
            return .color(hex: prim.hex)
        case "spacing":
            guard let prim = spec.primitives.spacing.first(where: { $0.name == name }) else {
                return nil
            }
            return .points(prim.points)
        case "radius":
            guard let prim = spec.primitives.radius.first(where: { $0.name == name }) else {
                return nil
            }
            return .points(prim.points)
        default:
            return nil
        }
    }

    // MARK: - Semantic resolution

    private func resolveSemantic(category: String, path: [String], appearance: Appearance) -> ResolvedValue? {
        // Semantic names may contain dots (e.g. `background.primary`), so reconstruct
        // the full name by joining the remaining path segments back together.
        guard !path.isEmpty else {
            return nil
        }
        let name = path.joined(separator: ".")
        switch category {
        case "color":
            guard let semantic = spec.semantic.color.first(where: { $0.name == name }) else {
                return nil
            }
            let ref = appearance == .light ? semantic.light : semantic.dark
            return resolve(ref, appearance: appearance)
        case "spacing":
            guard let alias = spec.semantic.spacing.first(where: { $0.name == name }) else {
                return nil
            }
            return resolve(alias.reference, appearance: appearance)
        case "radius":
            guard let alias = spec.semantic.radius.first(where: { $0.name == name }) else {
                return nil
            }
            return resolve(alias.reference, appearance: appearance)
        default:
            return nil
        }
    }

    // MARK: - Existence checks (structural validation)

    private func primitiveExists(category: String, tail: [String]) -> Bool {
        switch category {
        case "color":
            return tail.count == 1 && spec.primitives.color.contains { $0.name == tail[0] }
        case "spacing":
            return tail.count == 1 && spec.primitives.spacing.contains { $0.name == tail[0] }
        case "radius":
            return tail.count == 1 && spec.primitives.radius.contains { $0.name == tail[0] }
        case "elevation":
            return tail.count == 1 && spec.primitives.elevation.contains { $0.name == tail[0] }
        case "stroke":
            return tail.count == 1 && spec.primitives.stroke.contains { $0.name == tail[0] }
        case "typography":
            guard tail.count == 2 else {
                return false
            }
            switch tail[0] {
            case "fontFamilies":
                return spec.primitives.typography.fontFamilies.contains { $0.name == tail[1] }
            case "fontSizes":
                return spec.primitives.typography.fontSizes.contains { $0.name == tail[1] }
            case "fontWeights":
                return spec.primitives.typography.fontWeights.contains { $0.name == tail[1] }
            case "lineHeights":
                return spec.primitives.typography.lineHeights.contains { $0.name == tail[1] }
            default:
                return false
            }
        case "motion":
            guard tail.count == 2 else {
                return false
            }
            switch tail[0] {
            case "durations":
                return spec.primitives.motion.durations.contains { $0.name == tail[1] }
            case "curves":
                return spec.primitives.motion.curves.contains { $0.name == tail[1] }
            default:
                return false
            }
        default:
            return false
        }
    }

    private func semanticExists(category: String, tail: [String]) -> Bool {
        guard !tail.isEmpty else {
            return false
        }
        let name = tail.joined(separator: ".")
        switch category {
        case "color":
            return spec.semantic.color.contains { $0.name == name }
        case "type":
            return spec.semantic.type.contains { $0.name == name }
        case "spacing":
            return spec.semantic.spacing.contains { $0.name == name }
        case "radius":
            return spec.semantic.radius.contains { $0.name == name }
        default:
            return false
        }
    }
}

// MARK: - Types

nonisolated extension TokenResolver {

    enum Appearance: String, Sendable {
        case light
        case dark
    }

    enum ResolvedValue: Equatable, Sendable {
        case color(hex: String)
        case points(Double)
    }
}
