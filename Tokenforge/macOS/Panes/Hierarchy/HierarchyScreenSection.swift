//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct HierarchyScreenSection: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var screenStructure: [String] {
        document.spec.hierarchy.screenStructure
    }

    private var maxPrimary: Int {
        document.spec.hierarchy.maxPrimaryActionsPerArea
    }

    var body: some View {
        SectionCard(title: "Screen", aside: "\(screenStructure.count) sections") {
            Button {
                addSection()
            } label: {
                Label("Add Section", systemImage: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(Color.accentColor)
        } content: {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("PREFERRED TOP-LEVEL ORDER")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(.tertiary)
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(screenStructure.enumerated()), id: \.offset) { index, name in
                            HStack(spacing: 10) {
                                Text("\(index + 1).")
                                    .font(.system(size: 11, design: .monospaced))
                                    .monospacedDigit()
                                    .foregroundStyle(.tertiary)
                                    .frame(width: 22, alignment: .trailing)
                                CommitOnDefocusTextField(
                                    placeholder: "section name",
                                    source: name,
                                    font: .system(size: 12, design: .monospaced)
                                ) { new in
                                    updateSection(index: index, new: new)
                                }
                                .frame(maxWidth: 260, alignment: .leading)
                                Spacer(minLength: 6)
                            }
                            .padding(.vertical, 5)
                            .contextMenu {
                                Button(role: .destructive) {
                                    removeSection(index: index)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            if index < screenStructure.count - 1 {
                                Divider().opacity(0.4)
                            }
                        }
                    }
                }

                Divider().opacity(0.5)

                HStack(spacing: 12) {
                    Text("Max primary actions per area")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Stepper(value: Binding(
                        get: { maxPrimary },
                        set: { new in updateMaxPrimary(new) }
                    ), in: 1...5) {
                        Text("\(maxPrimary)")
                            .font(.system(size: 12, design: .monospaced))
                            .monospacedDigit()
                            .frame(width: 20, alignment: .trailing)
                    }
                    .labelsHidden()
                    Text("\(maxPrimary)")
                        .font(.system(size: 12, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: - Mutations

    private func addSection() {
        document.edit(actionName: "Add Screen Section", undoManager: undoManager) { spec in
            spec.hierarchy.screenStructure.append("new-section")
        }
    }

    private func removeSection(index: Int) {
        document.edit(actionName: "Delete Screen Section", undoManager: undoManager) { spec in
            guard index < spec.hierarchy.screenStructure.count else {
                return
            }
            spec.hierarchy.screenStructure.remove(at: index)
        }
    }

    private func updateSection(index: Int, new: String) {
        document.edit(actionName: "Edit Screen Section", undoManager: undoManager) { spec in
            guard index < spec.hierarchy.screenStructure.count else {
                return
            }
            spec.hierarchy.screenStructure[index] = new
        }
    }

    private func updateMaxPrimary(_ new: Int) {
        document.edit(actionName: "Edit Max Primary Actions", undoManager: undoManager) { spec in
            spec.hierarchy.maxPrimaryActionsPerArea = new
        }
    }
}
