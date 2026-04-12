//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct SemanticTypeSection: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var entries: [SemanticTextStyle] {
        document.spec.semantic.type
    }

    // Candidate lists for each typography primitive category.
    private var familyCandidates: [PrimitiveReferencePicker.Candidate] {
        document.spec.primitives.typography.fontFamilies.map {
            .init(name: $0.name, preview: .none)
        }
    }

    private var sizeCandidates: [PrimitiveReferencePicker.Candidate] {
        document.spec.primitives.typography.fontSizes.map {
            .init(name: $0.name, preview: .points($0.points))
        }
    }

    private var weightCandidates: [PrimitiveReferencePicker.Candidate] {
        document.spec.primitives.typography.fontWeights.map {
            .init(name: $0.name, preview: .none)
        }
    }

    private var lineHeightCandidates: [PrimitiveReferencePicker.Candidate] {
        document.spec.primitives.typography.lineHeights.map {
            .init(name: $0.name, preview: .none)
        }
    }

    var body: some View {
        SectionCard(title: "Typography", aside: "\(entries.count) text styles") {
            AddPrimitiveButton(action: addStyle)
        } content: {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(entries) { entry in
                    TypeRow(
                        entry: entry,
                        familyCandidates: familyCandidates,
                        sizeCandidates: sizeCandidates,
                        weightCandidates: weightCandidates,
                        lineHeightCandidates: lineHeightCandidates,
                        resolvedPreview: resolvedPreview(for: entry),
                        onRenameCommit: { new in rename(old: entry.name, new: new) },
                        onFamilyCommit: { ref in update(name: entry.name) { $0.fontFamily = ref } },
                        onSizeCommit: { ref in update(name: entry.name) { $0.fontSize = ref } },
                        onWeightCommit: { ref in update(name: entry.name) { $0.fontWeight = ref } },
                        onLineHeightCommit: { ref in update(name: entry.name) { $0.lineHeight = ref } },
                        onDelete: { delete(name: entry.name) }
                    )
                    if entry.id != entries.last?.id {
                        Divider().opacity(0.4)
                    }
                }
            }
        }
    }

    // MARK: - Resolved preview

    private func resolvedPreview(for entry: SemanticTextStyle) -> ResolvedTypePreview {
        let family = document.spec.primitives.typography.fontFamilies
            .first(where: { "{primitives.typography.fontFamilies.\($0.name)}" == entry.fontFamily.rawValue })
        let size = document.spec.primitives.typography.fontSizes
            .first(where: { "{primitives.typography.fontSizes.\($0.name)}" == entry.fontSize.rawValue })
        let weight = document.spec.primitives.typography.fontWeights
            .first(where: { "{primitives.typography.fontWeights.\($0.name)}" == entry.fontWeight.rawValue })
        let lineHeight = document.spec.primitives.typography.lineHeights
            .first(where: { "{primitives.typography.lineHeights.\($0.name)}" == entry.lineHeight.rawValue })
        return ResolvedTypePreview(
            familyName: family?.family,
            points: size?.points,
            cssWeight: weight?.weight,
            lineHeight: lineHeight?.multiplier
        )
    }

    // MARK: - Mutations

    private func addStyle() {
        document.edit(actionName: "Add Text Style", undoManager: undoManager) { spec in
            let baseName = "new-style"
            var candidate = baseName
            var suffix = 1
            let existing = Set(spec.semantic.type.map(\.name))
            while existing.contains(candidate) {
                suffix += 1
                candidate = "\(baseName)-\(suffix)"
            }
            let family = spec.primitives.typography.fontFamilies.first?.name ?? ""
            let size = spec.primitives.typography.fontSizes.first?.name ?? ""
            let weight = spec.primitives.typography.fontWeights.first?.name ?? ""
            let lineHeight = spec.primitives.typography.lineHeights.first?.name ?? ""
            spec.semantic.type.append(
                SemanticTextStyle(
                    name: candidate,
                    fontFamily: .primitivePath("typography", "fontFamilies", family),
                    fontSize: .primitivePath("typography", "fontSizes", size),
                    fontWeight: .primitivePath("typography", "fontWeights", weight),
                    lineHeight: .primitivePath("typography", "lineHeights", lineHeight)
                )
            )
        }
    }

    private func delete(name: String) {
        document.edit(actionName: "Delete Text Style", undoManager: undoManager) { spec in
            spec.semantic.type.removeAll { $0.name == name }
        }
    }

    private func rename(old: String, new: String) {
        guard old != new else {
            return
        }
        document.edit(actionName: "Rename Text Style", undoManager: undoManager) { spec in
            if let index = spec.semantic.type.firstIndex(where: { $0.name == old }) {
                spec.semantic.type[index].name = new
            }
            spec.rewriteAllReferences(
                from: .semantic("type", old),
                to: .semantic("type", new)
            )
        }
    }

    private func update(name: String, _ apply: (inout SemanticTextStyle) -> Void) {
        document.edit(actionName: "Edit Text Style", undoManager: undoManager) { spec in
            if let index = spec.semantic.type.firstIndex(where: { $0.name == name }) {
                apply(&spec.semantic.type[index])
            }
        }
    }
}

// MARK: - Row

private struct TypeRow: View {

    let entry: SemanticTextStyle
    let familyCandidates: [PrimitiveReferencePicker.Candidate]
    let sizeCandidates: [PrimitiveReferencePicker.Candidate]
    let weightCandidates: [PrimitiveReferencePicker.Candidate]
    let lineHeightCandidates: [PrimitiveReferencePicker.Candidate]
    let resolvedPreview: ResolvedTypePreview
    let onRenameCommit: (String) -> Void
    let onFamilyCommit: (TokenRef) -> Void
    let onSizeCommit: (TokenRef) -> Void
    let onWeightCommit: (TokenRef) -> Void
    let onLineHeightCommit: (TokenRef) -> Void
    let onDelete: () -> Void

    private var nameIsValid: Bool {
        KebabCase.isValid(entry.name)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ZStack(alignment: .trailing) {
                    CommitOnDefocusTextField(
                        placeholder: "name",
                        source: entry.name,
                        font: .system(size: 12, design: .monospaced),
                        onCommit: onRenameCommit
                    )
                    .foregroundStyle(nameIsValid ? Color.primary : Color.orange)
                    .frame(maxWidth: 180, alignment: .leading)
                    if !nameIsValid {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                    }
                }

                Divider()
                    .frame(height: 14)
                    .overlay(Color.primary.opacity(0.08))

                previewLabel
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                labeledPicker("FAMILY") {
                    PrimitiveReferencePicker(
                        currentReference: entry.fontFamily,
                        candidates: familyCandidates,
                        onCommit: onFamilyCommit,
                        referenceBuilder: { TokenRef.primitivePath("typography", "fontFamilies", $0) }
                    )
                }
                labeledPicker("SIZE") {
                    PrimitiveReferencePicker(
                        currentReference: entry.fontSize,
                        candidates: sizeCandidates,
                        onCommit: onSizeCommit,
                        referenceBuilder: { TokenRef.primitivePath("typography", "fontSizes", $0) }
                    )
                }
                labeledPicker("WEIGHT") {
                    PrimitiveReferencePicker(
                        currentReference: entry.fontWeight,
                        candidates: weightCandidates,
                        onCommit: onWeightCommit,
                        referenceBuilder: { TokenRef.primitivePath("typography", "fontWeights", $0) }
                    )
                }
                labeledPicker("LINE HEIGHT") {
                    PrimitiveReferencePicker(
                        currentReference: entry.lineHeight,
                        candidates: lineHeightCandidates,
                        onCommit: onLineHeightCommit,
                        referenceBuilder: { TokenRef.primitivePath("typography", "lineHeights", $0) }
                    )
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, 10)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var previewLabel: some View {
        let sampleSize = max(10, CGFloat(resolvedPreview.points ?? 14))
        let sampleWeight = fontWeight(for: resolvedPreview.cssWeight ?? 400)
        Text("Sample")
            .font(.system(size: sampleSize, weight: sampleWeight))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .frame(maxWidth: 180, alignment: .leading)
    }

    @ViewBuilder
    private func labeledPicker<Picker: View>(_ label: String, @ViewBuilder picker: () -> Picker) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.tertiary)
            picker()
        }
    }

    private func fontWeight(for cssWeight: Int) -> Font.Weight {
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

// MARK: - Resolved type preview

struct ResolvedTypePreview: Equatable {
    var familyName: String?
    var points: Double?
    var cssWeight: Int?
    var lineHeight: Double?
}
