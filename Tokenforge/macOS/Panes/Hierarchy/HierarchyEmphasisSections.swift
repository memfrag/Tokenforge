//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

// MARK: - Emphasis scale (1–5 with labels)

struct HierarchyEmphasisScaleSection: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var levels: [EmphasisLevel] {
        document.spec.hierarchy.emphasisScale
    }

    var body: some View {
        SectionCard(title: "Emphasis Scale", aside: "\(levels.count) levels") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(levels) { level in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(emphasisColor(for: level.level))
                                .frame(width: 22, height: 22)
                            Text("\(level.level)")
                                .font(.system(size: 11, weight: .bold))
                                .monospacedDigit()
                                .foregroundStyle(.white)
                        }
                        CommitOnDefocusTextField(
                            placeholder: "description",
                            source: level.label,
                            font: .system(size: 12)
                        ) { new in
                            updateLabel(level: level.level, label: new)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 7)
                    if level.id != levels.last?.id {
                        Divider().opacity(0.4)
                    }
                }
            }
        }
    }

    private func emphasisColor(for level: Int) -> Color {
        switch level {
        case 1: return Color.gray.opacity(0.55)
        case 2: return Color.gray
        case 3: return Color.blue.opacity(0.7)
        case 4: return Color.blue
        case 5: return Color.orange
        default: return Color.gray
        }
    }

    private func updateLabel(level: Int, label: String) {
        document.edit(actionName: "Edit Emphasis Label", undoManager: undoManager) { spec in
            if let index = spec.hierarchy.emphasisScale.firstIndex(where: { $0.level == level }) {
                spec.hierarchy.emphasisScale[index].label = label
            }
        }
    }
}

// MARK: - Type emphasis mapping

struct HierarchyTypeEmphasisSection: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var mappings: [TypeEmphasisMapping] {
        document.spec.hierarchy.typeEmphasis
    }

    private var typeCandidates: [PrimitiveReferencePicker.Candidate] {
        document.spec.semantic.type.map {
            PrimitiveReferencePicker.Candidate(name: $0.name, preview: .none)
        }
    }

    var body: some View {
        SectionCard(title: "Type Emphasis", aside: "\(mappings.count) mappings") {
            Button {
                addMapping()
            } label: {
                Label("Add Mapping", systemImage: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(Color.accentColor)
        } content: {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(mappings) { mapping in
                    HStack(spacing: 12) {
                        PrimitiveReferencePicker(
                            currentReference: mapping.typeStyle,
                            candidates: typeCandidates,
                            onCommit: { ref in updateStyle(id: mapping.id, ref: ref) },
                            referenceBuilder: { TokenRef.semantic("type", $0) }
                        )

                        Spacer(minLength: 8)

                        Text("Level")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                        Stepper(value: Binding(
                            get: { mapping.level },
                            set: { new in updateLevel(id: mapping.id, level: new) }
                        ), in: 1...5) {
                            EmptyView()
                        }
                        .labelsHidden()
                        Text("\(mapping.level)")
                            .font(.system(size: 12, design: .monospaced))
                            .monospacedDigit()
                            .frame(width: 16, alignment: .trailing)

                        Button {
                            delete(id: mapping.id)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 7)
                    if mapping.id != mappings.last?.id {
                        Divider().opacity(0.4)
                    }
                }
                if mappings.isEmpty {
                    Text("No mappings defined. Add one to tell the LLM which type style corresponds to which emphasis level.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 8)
                }
            }
        }
    }

    // MARK: - Mutations

    private func addMapping() {
        document.edit(actionName: "Add Type Emphasis", undoManager: undoManager) { spec in
            let fallback = spec.semantic.type.first?.name ?? ""
            spec.hierarchy.typeEmphasis.append(
                TypeEmphasisMapping(
                    typeStyle: .semantic("type", fallback),
                    level: 3
                )
            )
        }
    }

    private func delete(id: String) {
        document.edit(actionName: "Delete Type Emphasis", undoManager: undoManager) { spec in
            spec.hierarchy.typeEmphasis.removeAll { $0.id == id }
        }
    }

    private func updateStyle(id: String, ref: TokenRef) {
        document.edit(actionName: "Edit Type Emphasis Style", undoManager: undoManager) { spec in
            if let index = spec.hierarchy.typeEmphasis.firstIndex(where: { $0.id == id }) {
                spec.hierarchy.typeEmphasis[index].typeStyle = ref
            }
        }
    }

    private func updateLevel(id: String, level: Int) {
        document.edit(actionName: "Edit Type Emphasis Level", undoManager: undoManager) { spec in
            if let index = spec.hierarchy.typeEmphasis.firstIndex(where: { $0.id == id }) {
                spec.hierarchy.typeEmphasis[index].level = level
            }
        }
    }
}
