//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// Emits `llm-design-contract.md` — the markdown document the author hands
/// to an LLM to constrain its generation to the spec.
///
/// Layout:
/// 1. Header with spec name and version
/// 2. Natural-language system summary from `spec.meta.summary`
/// 3. Author's role prompt (if set)
/// 4. Derived "hard rules" — structural statements computed from the spec
///    itself (allowed tokens, allowed component variants, accessibility
///    constraints) concatenated with any author-added extra hard rules
/// 5. Author's free-text notes (if set)
/// 6. Token inventory appendix — the canonical lists of defined primitive
///    and semantic names so the LLM can cite them
/// 7. Baseline good/bad examples (hardcoded) + author extras
///
/// The derived sections always come first. If the author later renames a
/// primitive, the contract they re-export will reflect that automatically
/// without requiring them to edit their overrides.
///
nonisolated enum LLMContractExporter {

    static func export(_ spec: TokenforgeSpec) -> Data {
        var markdown = ""

        // Header
        markdown.append("# \(spec.meta.name)\n\n")
        markdown.append("_Version \(spec.meta.version), author: \(spec.meta.author)_\n\n")

        // Summary
        markdown.append("## System summary\n\n")
        markdown.append(spec.meta.summary.isEmpty
            ? "_No summary provided._\n\n"
            : "\(spec.meta.summary)\n\n"
        )

        // Role
        if !spec.llmContract.rolePrompt.isEmpty {
            markdown.append("## Role\n\n")
            markdown.append("\(spec.llmContract.rolePrompt)\n\n")
        }

        // Companion files — describes the rest of the export folder so the
        // LLM understands the full deliverable surface and can reference
        // values from each file by name.
        appendCompanionFilesSection(into: &markdown)

        // Hard rules — derived base + author extras
        markdown.append("## Hard rules\n\n")
        markdown.append("Treat this design system as a strict API, not inspiration.\n\n")
        for rule in derivedHardRules(for: spec) {
            markdown.append("- \(rule)\n")
        }
        for extra in spec.llmContract.extraHardRules {
            markdown.append("- \(extra)\n")
        }
        markdown.append("\n")

        // Notes
        if !spec.llmContract.notes.isEmpty {
            markdown.append("## Notes\n\n")
            markdown.append("\(spec.llmContract.notes)\n\n")
        }

        // Token inventory
        markdown.append("## Token inventory\n\n")
        appendInventorySection(
            title: "Semantic colors",
            items: spec.semantic.color.map(\.name),
            into: &markdown
        )
        appendInventorySection(
            title: "Semantic text styles",
            items: spec.semantic.type.map(\.name),
            into: &markdown
        )
        appendInventorySection(
            title: "Semantic spacing",
            items: spec.semantic.spacing.map(\.name),
            into: &markdown
        )
        appendInventorySection(
            title: "Semantic radius",
            items: spec.semantic.radius.map(\.name),
            into: &markdown
        )
        appendInventorySection(
            title: "Available components",
            items: [
                "button", "card", "textField", "listItem",
                "navBar", "tabBar", "toolbar", "segmentedControl",
                "toggle", "alert", "toastBanner", "badgeTag"
            ],
            into: &markdown
        )

        // Hierarchy rules
        if !spec.hierarchy.rules.isEmpty {
            markdown.append("## Hierarchy rules\n\n")
            for rule in spec.hierarchy.rules {
                markdown.append("- **\(rule.kind.rawValue)**: \(rule.text)\n")
            }
            markdown.append("\n")
        }

        // Emphasis scale
        if !spec.hierarchy.emphasisScale.isEmpty {
            markdown.append("## Emphasis scale\n\n")
            for level in spec.hierarchy.emphasisScale {
                markdown.append("- **\(level.level)** — \(level.label)\n")
            }
            markdown.append("\n")
        }

        // Examples — hardcoded baseline + author extras
        markdown.append("## Examples\n\n")
        for baseline in Self.baselineExamples {
            markdown.append("### Good — \(baseline.title)\n\n")
            markdown.append("```yaml\n\(baseline.yaml)\n```\n\n")
        }
        for anti in Self.baselineAntiPatterns {
            markdown.append("### Bad — \(anti.title)\n\n")
            markdown.append("\(anti.description)\n\n")
        }
        for extra in spec.examples.items {
            let heading = extra.kind == .good ? "Good" : "Bad"
            let caption = extra.caption.isEmpty ? "(author example)" : extra.caption
            markdown.append("### \(heading) — \(caption)\n\n")
            markdown.append("```yaml\n\(extra.yaml)\n```\n\n")
        }

        return Data(markdown.utf8)
    }

    // MARK: - Derived hard rules

    private static func derivedHardRules(for spec: TokenforgeSpec) -> [String] {
        var rules: [String] = []
        rules.append("Use only tokens defined in this spec. Do not invent colors, spacing values, or type styles.")
        rules.append("Use only the twelve listed component variants.")
        rules.append("Minimum tap target is \(Int(spec.accessibility.minTapTargetPoints))×\(Int(spec.accessibility.minTapTargetPoints)) points.")
        rules.append("Minimum contrast is \(spec.accessibility.minContrast).")
        if spec.accessibility.dynamicTypeSupport {
            rules.append("Support Dynamic Type.")
        }
        rules.append("Only one primary action visible per local action group (max \(spec.hierarchy.maxPrimaryActionsPerArea)).")
        return rules
    }

    private static func appendInventorySection(
        title: String,
        items: [String],
        into markdown: inout String
    ) {
        markdown.append("**\(title):**\n\n")
        if items.isEmpty {
            markdown.append("_None defined._\n\n")
            return
        }
        for item in items {
            markdown.append("- `\(item)`\n")
        }
        markdown.append("\n")
    }

    // MARK: - Companion files

    /// Describes the other files Tokenforge writes alongside this markdown
    /// in an `Export All` run, so the LLM understands the full deliverable
    /// surface even if a user only pastes the markdown into a chat.
    ///
    /// Filenames are referenced literally — they match `ExportBundle.FileName`
    /// and `AssetCatalogExporter.catalogDirectory` constants exactly.
    ///
    private static func appendCompanionFilesSection(into markdown: inout String) {
        markdown.append("## Companion files\n\n")
        markdown.append("This contract is one file in a larger exported deliverable. The full export folder contains:\n\n")
        markdown.append("- `\(ExportBundle.FileName.llmContractMarkdown)` — this document. Hard rules, token inventory, hierarchy rules, and good/bad examples. Read this first.\n")
        markdown.append("- `\(ExportBundle.FileName.designTokensJSON)` — the canonical token dictionary in lossless JSON. Mirrors the layered shape used by Tokenforge: `primitives.{color, spacing, radius, typography, elevation, stroke, motion}`, `semantic.{color, type, spacing, radius}`, `hierarchy`, `components`, `accessibility`. Use it when you need exact token paths or when generating non-Swift code.\n")
        markdown.append("- `\(ExportBundle.FileName.componentSpecsYAML)` — the twelve component contracts in YAML. Each entry lists variants, sizes, states, and rules. Reference this when discussing or generating any of: button, card, textField, listItem, navBar, tabBar, toolbar, segmentedControl, toggle, alert, toastBanner, badgeTag.\n")
        markdown.append("- `\(ExportBundle.FileName.hierarchyRulesYAML)` — preferred screen structure, the 1–5 emphasis scale, the per-rule kind tags (`text` / `action` / `emphasis` / `do` / `dont`), and the type-style → emphasis-level mapping. Use this to preserve attention hierarchy across generated screens.\n")
        markdown.append("- `\(ExportBundle.FileName.swiftTokenMapping)` — generated SwiftUI source. Defines `Color.<semanticName>` per semantic color (camelCased from kebab — e.g. `action.primary.bg` becomes `Color.actionPrimaryBg`), plus `AppSpacing.<alias>` and `AppRadius.<alias>` constants. **When generating SwiftUI code, use these identifiers verbatim** — do not invent new ones, do not hardcode hex values or point literals.\n")
        markdown.append("- `\(AssetCatalogExporter.catalogDirectory)/` — Xcode asset catalog with one `.colorset` per semantic color, each carrying both light- and dark-appearance hex values. The Swift file references entries by name; consumers drop this folder into their Xcode project and Color resolution becomes appearance-aware automatically.\n")
        markdown.append("\n")
        markdown.append("Treat the union of these files as the strict API. Do not invent tokens, components, or hierarchy concepts that aren't present. If a needed concept is missing, say so explicitly and ask for it to be added — don't fabricate.\n\n")
    }

    // MARK: - Hardcoded baseline examples

    private struct Example {
        var title: String
        var yaml: String
    }

    private struct AntiExample {
        var title: String
        var description: String
    }

    private static let baselineExamples: [Example] = [
        Example(
            title: "Payment Details",
            yaml: """
            name: Payment Details
            hierarchy:
              primaryFocus: amount_due
              secondaryFocus: due_date
              tertiaryFocus: transaction_history
            structure:
              - topBar
              - summaryCard
              - detailSection
              - primaryAction
            tokens:
              title: semantic.type.titleLarge
              body: semantic.type.body
              cardRadius: semantic.radius.card
            """
        )
    ]

    private static let baselineAntiPatterns: [AntiExample] = [
        AntiExample(
            title: "Double primary buttons",
            description: """
            - Two primary buttons in the same section
            - Accent color used for decorative labels
            - Caption style used for important balance amount
            - More than one h1-equivalent title on the same screen
            """
        )
    ]
}
