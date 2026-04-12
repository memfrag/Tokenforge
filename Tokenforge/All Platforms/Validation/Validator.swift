//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Pure validator over a `TokenforgeSpec`. No observation, no mutation,
/// no side effects — just read the current state of the spec and return
/// an array of findings sorted by severity then breadcrumb.
///
/// The validator is called on every render by `InspectorPanel` and the
/// toolbar chip; keep it fast. Reference extraction is done via a single
/// JSON encode + regex scan so we don't have to enumerate every `TokenRef`
/// field site by hand.
///
nonisolated enum Validator {

    static func validate(_ spec: TokenforgeSpec) -> [Problem] {
        var problems: [Problem] = []

        // MARK: Duplicate primitive names

        detectDuplicateNames(
            in: spec.primitives.color.map(\.name),
            pane: .primitives,
            breadcrumb: "Color",
            kind: "color",
            into: &problems
        )
        detectDuplicateNames(
            in: spec.primitives.spacing.map(\.name),
            pane: .primitives,
            breadcrumb: "Spacing",
            kind: "spacing value",
            into: &problems
        )
        detectDuplicateNames(
            in: spec.primitives.radius.map(\.name),
            pane: .primitives,
            breadcrumb: "Radius",
            kind: "radius value",
            into: &problems
        )
        detectDuplicateNames(
            in: spec.primitives.typography.fontFamilies.map(\.name),
            pane: .primitives,
            breadcrumb: "Typography · Font Families",
            kind: "font family",
            into: &problems
        )
        detectDuplicateNames(
            in: spec.primitives.typography.fontSizes.map(\.name),
            pane: .primitives,
            breadcrumb: "Typography · Font Sizes",
            kind: "font size",
            into: &problems
        )
        detectDuplicateNames(
            in: spec.primitives.typography.fontWeights.map(\.name),
            pane: .primitives,
            breadcrumb: "Typography · Font Weights",
            kind: "font weight",
            into: &problems
        )
        detectDuplicateNames(
            in: spec.primitives.typography.lineHeights.map(\.name),
            pane: .primitives,
            breadcrumb: "Typography · Line Heights",
            kind: "line height",
            into: &problems
        )
        detectDuplicateNames(
            in: spec.primitives.elevation.map(\.name),
            pane: .primitives,
            breadcrumb: "Elevation",
            kind: "elevation",
            into: &problems
        )
        detectDuplicateNames(
            in: spec.primitives.stroke.map(\.name),
            pane: .primitives,
            breadcrumb: "Stroke",
            kind: "stroke",
            into: &problems
        )
        detectDuplicateNames(
            in: spec.primitives.motion.durations.map(\.name),
            pane: .primitives,
            breadcrumb: "Motion · Durations",
            kind: "duration",
            into: &problems
        )
        detectDuplicateNames(
            in: spec.primitives.motion.curves.map(\.name),
            pane: .primitives,
            breadcrumb: "Motion · Curves",
            kind: "curve",
            into: &problems
        )

        // MARK: Duplicate semantic names

        detectDuplicateNames(
            in: spec.semantic.color.map(\.name),
            pane: .semantic,
            breadcrumb: "Color",
            kind: "semantic color",
            into: &problems
        )
        detectDuplicateNames(
            in: spec.semantic.type.map(\.name),
            pane: .semantic,
            breadcrumb: "Typography",
            kind: "text style",
            into: &problems
        )
        detectDuplicateNames(
            in: spec.semantic.spacing.map(\.name),
            pane: .semantic,
            breadcrumb: "Spacing",
            kind: "spacing alias",
            into: &problems
        )
        detectDuplicateNames(
            in: spec.semantic.radius.map(\.name),
            pane: .semantic,
            breadcrumb: "Radius",
            kind: "radius alias",
            into: &problems
        )

        // MARK: Kebab-case lint warnings

        detectKebabViolations(
            in: spec.primitives.color.map(\.name),
            pane: .primitives,
            breadcrumb: "Color",
            into: &problems
        )
        detectKebabViolations(
            in: spec.primitives.spacing.map(\.name),
            pane: .primitives,
            breadcrumb: "Spacing",
            into: &problems
        )
        detectKebabViolations(
            in: spec.primitives.radius.map(\.name),
            pane: .primitives,
            breadcrumb: "Radius",
            into: &problems
        )
        detectKebabViolations(
            in: spec.primitives.typography.fontFamilies.map(\.name),
            pane: .primitives,
            breadcrumb: "Typography · Font Families",
            into: &problems
        )
        detectKebabViolations(
            in: spec.primitives.typography.fontSizes.map(\.name),
            pane: .primitives,
            breadcrumb: "Typography · Font Sizes",
            into: &problems
        )
        detectKebabViolations(
            in: spec.primitives.typography.fontWeights.map(\.name),
            pane: .primitives,
            breadcrumb: "Typography · Font Weights",
            into: &problems
        )
        detectKebabViolations(
            in: spec.primitives.typography.lineHeights.map(\.name),
            pane: .primitives,
            breadcrumb: "Typography · Line Heights",
            into: &problems
        )
        detectKebabViolations(
            in: spec.primitives.elevation.map(\.name),
            pane: .primitives,
            breadcrumb: "Elevation",
            into: &problems
        )
        detectKebabViolations(
            in: spec.primitives.stroke.map(\.name),
            pane: .primitives,
            breadcrumb: "Stroke",
            into: &problems
        )
        detectKebabViolations(
            in: spec.primitives.motion.durations.map(\.name),
            pane: .primitives,
            breadcrumb: "Motion · Durations",
            into: &problems
        )
        detectKebabViolations(
            in: spec.primitives.motion.curves.map(\.name),
            pane: .primitives,
            breadcrumb: "Motion · Curves",
            into: &problems
        )
        // Semantic names are not kebab-linted in Phase 6 — the bundled
        // DefaultSpec uses camelCase conventions that a future starter-kit
        // pass will normalize. Primitive names are the ones that feed into
        // the Swift export and need strict kebab adherence.

        // MARK: Reference scan — unresolved refs and unused primitives

        let scan = scanReferences(in: spec)
        let resolver = TokenResolver(spec: spec)

        for ref in scan.usedReferences.sorted() {
            let token = TokenRef(rawValue: ref)
            if !resolver.referenceExists(token) {
                problems.append(Problem(
                    severity: .error,
                    pane: paneForReference(ref),
                    breadcrumb: breadcrumbForReference(ref),
                    title: "Unresolved reference",
                    detail: ref
                ))
            }
        }

        // Unused primitive warnings — intentionally limited to primitives we can
        // cheaply enumerate. Typography sub-categories, motion, stroke, and
        // elevation are skipped because Phase 6 hasn't wired components to
        // reference them yet.
        let referenceSet = scan.usedReferences

        for primitive in spec.primitives.color
        where !referenceSet.contains(TokenRef.primitive("color", primitive.name).rawValue) {
            problems.append(Problem(
                severity: .warning,
                pane: .primitives,
                breadcrumb: "Color",
                title: "Unused primitive",
                detail: primitive.name
            ))
        }
        for primitive in spec.primitives.spacing
        where !referenceSet.contains(TokenRef.primitive("spacing", primitive.name).rawValue) {
            problems.append(Problem(
                severity: .warning,
                pane: .primitives,
                breadcrumb: "Spacing",
                title: "Unused primitive",
                detail: primitive.name
            ))
        }
        for primitive in spec.primitives.radius
        where !referenceSet.contains(TokenRef.primitive("radius", primitive.name).rawValue) {
            problems.append(Problem(
                severity: .warning,
                pane: .primitives,
                breadcrumb: "Radius",
                title: "Unused primitive",
                detail: primitive.name
            ))
        }

        // Unused-semantic warnings were deliberately dropped in Phase 12.
        //
        // Semantic tokens are author-defined vocabulary; a design system can
        // legitimately define more semantic entries than any component
        // consumes. Unlike unused primitives — which bloat the Swift export
        // and asset catalog — unused semantics are cheap and often valuable
        // as a vocabulary for future work. Flagging them created churn on
        // every new semantic entry without corresponding value.

        // Sort: errors first, then warnings, then alphabetically by breadcrumb.
        return problems.sorted { lhs, rhs in
            if lhs.severity != rhs.severity {
                return lhs.severity < rhs.severity
            }
            if lhs.breadcrumb != rhs.breadcrumb {
                return lhs.breadcrumb < rhs.breadcrumb
            }
            return (lhs.detail ?? "") < (rhs.detail ?? "")
        }
    }

    // MARK: - Duplicate name detection

    private static func detectDuplicateNames(
        in names: [String],
        pane: Problem.Pane,
        breadcrumb: String,
        kind: String,
        into problems: inout [Problem]
    ) {
        var seen: Set<String> = []
        var duplicates: Set<String> = []
        for name in names {
            if !seen.insert(name).inserted {
                duplicates.insert(name)
            }
        }
        for name in duplicates.sorted() {
            problems.append(Problem(
                severity: .error,
                pane: pane,
                breadcrumb: breadcrumb,
                title: "Duplicate \(kind) name",
                detail: name
            ))
        }
    }

    // MARK: - Kebab lint

    private static func detectKebabViolations(
        in names: [String],
        pane: Problem.Pane,
        breadcrumb: String,
        into problems: inout [Problem]
    ) {
        for name in names where !KebabCase.isValid(name) {
            problems.append(Problem(
                severity: .warning,
                pane: pane,
                breadcrumb: breadcrumb,
                title: "Name not in kebab-case",
                detail: name
            ))
        }
    }

    // MARK: - Reference scan

    private struct ReferenceScan {
        var usedReferences: Set<String>
    }

    /// Encodes the spec to JSON and pulls out every `"{...}"` substring that
    /// matches the `TokenRef` shape. Uses a single pass through the encoded
    /// text — cheap for the sizes Tokenforge specs are expected to reach.
    private static func scanReferences(in spec: TokenforgeSpec) -> ReferenceScan {
        var refs: Set<String> = []
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            let data = try encoder.encode(spec)
            guard let text = String(data: data, encoding: .utf8) else {
                return ReferenceScan(usedReferences: [])
            }
            // Look for `"{...}"` spans. Manual scan avoids a Regex dependency.
            var index = text.startIndex
            while let openQuote = text[index...].firstIndex(of: "\"") {
                let afterQuote = text.index(after: openQuote)
                guard afterQuote < text.endIndex, text[afterQuote] == "{" else {
                    index = afterQuote
                    continue
                }
                // Find the matching closing brace followed by a quote.
                guard let closeBrace = text[afterQuote...].firstIndex(of: "}") else {
                    break
                }
                let afterBrace = text.index(after: closeBrace)
                guard afterBrace < text.endIndex, text[afterBrace] == "\"" else {
                    index = afterBrace
                    continue
                }
                let ref = String(text[afterQuote...closeBrace])
                refs.insert(ref)
                index = text.index(after: afterBrace)
            }
        } catch {
            // Fall through with the refs we've collected so far.
        }
        return ReferenceScan(usedReferences: refs)
    }

    // MARK: - Routing refs to panes

    private static func paneForReference(_ ref: String) -> Problem.Pane {
        // `{primitives.*}` → Primitives, `{semantic.*}` → Semantic, otherwise Components.
        if ref.hasPrefix("{primitives.") {
            return .primitives
        }
        if ref.hasPrefix("{semantic.") {
            return .semantic
        }
        return .components
    }

    private static func breadcrumbForReference(_ ref: String) -> String {
        // Strip braces and take the first two path segments for a readable
        // breadcrumb, e.g. "primitives · color" from "{primitives.color.blue-500}".
        guard ref.hasPrefix("{"), ref.hasSuffix("}") else {
            return ref
        }
        let inner = ref.dropFirst().dropLast()
        let parts = inner.split(separator: ".").prefix(2)
        return parts.joined(separator: " · ")
    }
}
