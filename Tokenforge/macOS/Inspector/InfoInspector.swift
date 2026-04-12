//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// Content of the right-hand Inspector's Info tab. Phase 11 version shows
/// a per-pane summary: counts, key stats, and — when Engineering Mode is
/// on — an expandable raw JSON viewer for `spec.json`.
///
/// Token-level selection routing (click a field → selected in inspector)
/// is deferred until Phase 13 polish. For Phase 11 the Info tab gives the
/// author a reliable at-a-glance read of what's in the active pane.
///
struct InfoInspector: View {

    let document: TokenforgeDocument
    let activePane: SidebarPane

    @Environment(EngineeringMode.self) private var engineeringMode

    // Raw JSON viewer state. Collapsed by default so switching to the Info
    // tab is instant — encoding + textSelection layout over a large spec
    // used to block the main thread on every tab switch AND every keystroke.
    @State private var isRawJSONExpanded: Bool = false
    @State private var rawJSONCache: String?
    @State private var rawJSONTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                summary
                if engineeringMode.isEnabled {
                    rawJSONSection
                }
            }
            .padding(16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onDisappear {
            rawJSONTask?.cancel()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    private var title: String {
        switch activePane {
        case .primitives: return "Primitives"
        case .semantic: return "Semantic layer"
        case .hierarchy: return "Hierarchy rules"
        case .components: return "Component contracts"
        case .preview: return "Preview"
        case .contract: return "Contract & Export"
        case .fonts: return "Fonts"
        case .icons: return "Icons"
        }
    }

    private var subtitle: String {
        switch activePane {
        case .primitives: return "Raw, unreferenced values."
        case .semantic: return "Aliases that reference primitives."
        case .hierarchy: return "How the spec describes attention."
        case .components: return "12 built-in component shapes."
        case .preview: return "Live render of the current spec."
        case .contract: return "LLM contract + export outputs."
        case .fonts: return "Custom TTF / OTF files bundled with the document."
        case .icons: return "Custom PNG / PDF / SVG files bundled with the document."
        }
    }

    // MARK: - Summary

    @ViewBuilder
    private var summary: some View {
        switch activePane {
        case .primitives:
            KeyValueGroup(pairs: primitiveSummaryPairs)
        case .semantic:
            KeyValueGroup(pairs: semanticSummaryPairs)
        case .hierarchy:
            KeyValueGroup(pairs: hierarchySummaryPairs)
        case .components:
            KeyValueGroup(pairs: componentsSummaryPairs)
        case .preview:
            KeyValueGroup(pairs: previewSummaryPairs)
        case .contract:
            KeyValueGroup(pairs: contractSummaryPairs)
        case .fonts:
            KeyValueGroup(pairs: fontsSummaryPairs)
        case .icons:
            KeyValueGroup(pairs: iconsSummaryPairs)
        }
    }

    private var fontsSummaryPairs: [KeyValuePair] {
        let bytes = document.fontData.values.reduce(0) { $0 + $1.count }
        return [
            KeyValuePair("Files", "\(document.fontData.count)"),
            KeyValuePair("Registered", "\(FontRegistry.postScriptNames.count)"),
            KeyValuePair("Total bytes", "\(bytes)")
        ]
    }

    private var iconsSummaryPairs: [KeyValuePair] {
        let bytes = document.iconData.values.reduce(0) { $0 + $1.count }
        return [
            KeyValuePair("SF Symbols", "\(document.spec.iconSet.sfSymbols.count)"),
            KeyValuePair("Files", "\(document.iconData.count)"),
            KeyValuePair("Total bytes", "\(bytes)")
        ]
    }

    // MARK: - Per-pane pairs

    private var primitiveSummaryPairs: [KeyValuePair] {
        let primitives = document.spec.primitives
        return [
            KeyValuePair("Colors", "\(primitives.color.count)"),
            KeyValuePair("Spacing", "\(primitives.spacing.count)"),
            KeyValuePair("Radius", "\(primitives.radius.count)"),
            KeyValuePair("Font families", "\(primitives.typography.fontFamilies.count)"),
            KeyValuePair("Font sizes", "\(primitives.typography.fontSizes.count)"),
            KeyValuePair("Font weights", "\(primitives.typography.fontWeights.count)"),
            KeyValuePair("Line heights", "\(primitives.typography.lineHeights.count)"),
            KeyValuePair("Elevation", "\(primitives.elevation.count)"),
            KeyValuePair("Stroke", "\(primitives.stroke.count)"),
            KeyValuePair("Durations", "\(primitives.motion.durations.count)"),
            KeyValuePair("Curves", "\(primitives.motion.curves.count)")
        ]
    }

    private var semanticSummaryPairs: [KeyValuePair] {
        let semantic = document.spec.semantic
        return [
            KeyValuePair("Colors", "\(semantic.color.count)"),
            KeyValuePair("Text styles", "\(semantic.type.count)"),
            KeyValuePair("Spacing aliases", "\(semantic.spacing.count)"),
            KeyValuePair("Radius aliases", "\(semantic.radius.count)")
        ]
    }

    private var hierarchySummaryPairs: [KeyValuePair] {
        let hierarchy = document.spec.hierarchy
        let kinds = Dictionary(grouping: hierarchy.rules, by: { $0.kind })
        var pairs: [KeyValuePair] = [
            KeyValuePair("Screen sections", "\(hierarchy.screenStructure.count)"),
            KeyValuePair("Max primary actions", "\(hierarchy.maxPrimaryActionsPerArea)"),
            KeyValuePair("Total rules", "\(hierarchy.rules.count)"),
            KeyValuePair("Emphasis levels", "\(hierarchy.emphasisScale.count)"),
            KeyValuePair("Type emphasis mappings", "\(hierarchy.typeEmphasis.count)")
        ]
        for kind in [HierarchyRuleKind.text, .action, .emphasis, .do, .dont] {
            pairs.append(KeyValuePair("… \(kind.displayName)", "\(kinds[kind]?.count ?? 0)"))
        }
        return pairs
    }

    private var componentsSummaryPairs: [KeyValuePair] {
        let components = document.spec.components
        return [
            KeyValuePair("button rules", "\(components.button.rules.count)"),
            KeyValuePair("card rules", "\(components.card.rules.count)"),
            KeyValuePair("card slots", "\(components.card.allowedSlots.count)"),
            KeyValuePair("textField rules", "\(components.textField.rules.count)"),
            KeyValuePair("listItem rules", "\(components.listItem.rules.count)"),
            KeyValuePair("navBar rules", "\(components.navBar.rules.count)"),
            KeyValuePair("tabBar rules", "\(components.tabBar.rules.count)"),
            KeyValuePair("toolbar rules", "\(components.toolbar.rules.count)"),
            KeyValuePair("segmentedControl rules", "\(components.segmentedControl.rules.count)"),
            KeyValuePair("toggle rules", "\(components.toggle.rules.count)"),
            KeyValuePair("alert rules", "\(components.alert.rules.count)"),
            KeyValuePair("toastBanner rules", "\(components.toastBanner.rules.count)"),
            KeyValuePair("badgeTag rules", "\(components.badgeTag.rules.count)")
        ]
    }

    private var previewSummaryPairs: [KeyValuePair] {
        [
            KeyValuePair("Samples", "4"),
            KeyValuePair("Implemented", "4"),
            KeyValuePair("Registered fonts", "\(FontRegistry.postScriptNames.count)"),
            KeyValuePair("Icons available", "\(document.manifest.iconFilenames.count)")
        ]
    }

    private var contractSummaryPairs: [KeyValuePair] {
        let contract = document.spec.llmContract
        let examples = document.spec.examples
        return [
            KeyValuePair("Role prompt", contract.rolePrompt.isEmpty ? "—" : "\(contract.rolePrompt.count) chars"),
            KeyValuePair("Extra hard rules", "\(contract.extraHardRules.count)"),
            KeyValuePair("Notes", contract.notes.isEmpty ? "—" : "\(contract.notes.count) chars"),
            KeyValuePair("Author examples", "\(examples.items.count)")
        ]
    }

    // MARK: - Raw JSON

    /// Collapsed-by-default raw JSON viewer. Tab switching doesn't pay for
    /// any encoding work because the disclosure body isn't evaluated until
    /// the user opens it. When open, `scheduleEncoding()` runs
    /// `spec.encodeJSON()` on a detached `Task` (the spec types are
    /// `nonisolated` so the encode happens off-main), then hops back to
    /// the main actor to update `rawJSONCache`. Subsequent spec edits
    /// cancel the in-flight task and kick a fresh one, so the view stays
    /// live while the disclosure is open — but collapsing it tears
    /// everything down again.
    private var rawJSONSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider().opacity(0.4)
            DisclosureGroup(isExpanded: $isRawJSONExpanded) {
                rawJSONBody
                    .padding(.top, 6)
            } label: {
                Text("RAW SPEC.JSON")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(.tertiary)
            }
            .onChange(of: isRawJSONExpanded) { _, expanded in
                if expanded {
                    scheduleEncoding()
                } else {
                    rawJSONTask?.cancel()
                    rawJSONTask = nil
                    rawJSONCache = nil
                }
            }
            .onChange(of: document.spec) { _, _ in
                guard isRawJSONExpanded else {
                    return
                }
                scheduleEncoding()
            }
        }
    }

    @ViewBuilder
    private var rawJSONBody: some View {
        Group {
            if let rawJSONCache {
                ScrollView {
                    Text(rawJSONCache)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 220)
            } else {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Encoding spec.json…")
                        .font(.system(size: 10.5))
                        .foregroundStyle(.tertiary)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(.separator, lineWidth: 0.5)
        )
    }

    /// Kicks off a background encoding task. Cancels any in-flight task
    /// first and clears the cache so the UI shows the loading state until
    /// the fresh encode lands.
    private func scheduleEncoding() {
        rawJSONTask?.cancel()
        rawJSONCache = nil
        let spec = document.spec
        rawJSONTask = Task.detached(priority: .userInitiated) {
            let encoded: String
            if let data = try? spec.encodeJSON(),
               let string = String(data: data, encoding: .utf8) {
                encoded = string
            } else {
                encoded = "(unencodable)"
            }
            if Task.isCancelled {
                return
            }
            await MainActor.run {
                rawJSONCache = encoded
            }
        }
    }
}

// MARK: - Key/value row group

struct KeyValuePair: Identifiable, Hashable {
    var id: String { label }
    let label: String
    let value: String

    init(_ label: String, _ value: String) {
        self.label = label
        self.value = value
    }
}

private struct KeyValueGroup: View {
    let pairs: [KeyValuePair]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(pairs) { pair in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(pair.label)
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 6)
                    Text(pair.value)
                        .font(.system(size: 11.5, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, 5)
                if pair.id != pairs.last?.id {
                    Divider().opacity(0.35)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor).opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(.separator, lineWidth: 0.5)
        )
    }
}
