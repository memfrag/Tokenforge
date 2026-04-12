//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// Editor for `spec.llmContract` — the author's role prompt, extra hard
/// rules, and free-text notes that the LLM contract markdown exporter
/// concatenates after the derived base.
///
/// The role prompt and notes are multi-line vertical text fields. The
/// extra hard rules are a repeater of single-line strings with add /
/// edit / delete affordances, mirroring the rule-list pattern used by
/// `HierarchyRulesSection`.
///
struct ContractOverridesSection: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var contract: LLMContractOverrides {
        document.spec.llmContract
    }

    var body: some View {
        SectionCard(title: "LLM Contract Overrides", aside: "appended after derived base") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 18) {
                rolePromptField
                extraRulesEditor
                notesField
            }
        }
    }

    // MARK: - Role prompt

    private var rolePromptField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ROLE PROMPT")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.tertiary)
            CommitOnDefocusTextField(
                placeholder: "You are designing iOS screens using the attached design system…",
                source: contract.rolePrompt,
                font: .system(size: 13),
                axis: .vertical,
                lineLimit: 3...8
            ) { new in
                update { $0.rolePrompt = new }
            }
        }
    }

    // MARK: - Extra hard rules

    private var extraRulesEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("EXTRA HARD RULES")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(.tertiary)
                Spacer(minLength: 0)
                Button {
                    addRule()
                } label: {
                    Label("Add Rule", systemImage: "plus")
                        .font(.system(size: 11, weight: .medium))
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(Color.accentColor)
            }
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(contract.extraHardRules.enumerated()), id: \.offset) { index, rule in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(index + 1).")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .frame(width: 22, alignment: .trailing)
                        CommitOnDefocusTextField(
                            placeholder: "Hard rule",
                            source: rule,
                            font: .system(size: 13)
                        ) { new in
                            updateRule(at: index, new: new)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Button {
                            removeRule(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 6)
                    if index < contract.extraHardRules.count - 1 {
                        Divider().opacity(0.4)
                    }
                }
                if contract.extraHardRules.isEmpty {
                    Text("No extra rules. The exported contract will only include the rules derived from the spec.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 6)
                }
            }
        }
    }

    // MARK: - Notes

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NOTES")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.tertiary)
            CommitOnDefocusTextField(
                placeholder: "Free-form notes appended after the hard rules in the exported markdown.",
                source: contract.notes,
                font: .system(size: 13),
                axis: .vertical,
                lineLimit: 3...8
            ) { new in
                update { $0.notes = new }
            }
        }
    }

    // MARK: - Mutations

    private func update(_ apply: (inout LLMContractOverrides) -> Void) {
        document.edit(actionName: "Edit LLM Contract", undoManager: undoManager) { spec in
            apply(&spec.llmContract)
        }
    }

    private func addRule() {
        update { $0.extraHardRules.append("New rule") }
    }

    private func removeRule(at index: Int) {
        update { draft in
            guard index < draft.extraHardRules.count else {
                return
            }
            draft.extraHardRules.remove(at: index)
        }
    }

    private func updateRule(at index: Int, new: String) {
        update { draft in
            guard index < draft.extraHardRules.count else {
                return
            }
            draft.extraHardRules[index] = new
        }
    }
}
