//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct SemanticSpacingSection: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var entries: [SemanticAlias] {
        document.spec.semantic.spacing
    }

    private var resolver: TokenResolver {
        TokenResolver(spec: document.spec)
    }

    private var spacingCandidates: [PrimitiveReferencePicker.Candidate] {
        document.spec.primitives.spacing.map { primitive in
            PrimitiveReferencePicker.Candidate(
                name: primitive.name,
                preview: .points(primitive.points)
            )
        }
    }

    var body: some View {
        SectionCard(title: "Spacing", aside: "\(entries.count) aliases") {
            AddPrimitiveButton(action: addAlias)
        } content: {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(entries) { entry in
                    AliasRow(
                        name: entry.name,
                        reference: entry.reference,
                        candidates: spacingCandidates,
                        referenceBuilder: { TokenRef.primitive("spacing", $0) },
                        resolvedLabel: resolvedLabel(entry.reference),
                        onRenameCommit: { new in rename(old: entry.name, new: new) },
                        onReferenceCommit: { ref in updateReference(name: entry.name, newRef: ref) },
                        onDelete: { delete(name: entry.name) }
                    )
                    if entry.id != entries.last?.id {
                        Divider().opacity(0.4)
                    }
                }
            }
        }
    }

    private func resolvedLabel(_ ref: TokenRef) -> String {
        if case .points(let value) = resolver.resolve(ref) {
            return "\(formatted(value)) pt"
        }
        return "unresolved"
    }

    private func formatted(_ value: Double) -> String {
        value.rounded() == value
            ? String(format: "%.0f", value)
            : String(format: "%.2f", value)
    }

    // MARK: - Mutations

    private func addAlias() {
        document.edit(actionName: "Add Spacing Alias", undoManager: undoManager) { spec in
            let baseName = "new-alias"
            var candidate = baseName
            var suffix = 1
            let existing = Set(spec.semantic.spacing.map(\.name))
            while existing.contains(candidate) {
                suffix += 1
                candidate = "\(baseName)-\(suffix)"
            }
            let fallback = spec.primitives.spacing.first?.name ?? ""
            spec.semantic.spacing.append(
                SemanticAlias(name: candidate, reference: .primitive("spacing", fallback))
            )
        }
    }

    private func delete(name: String) {
        document.edit(actionName: "Delete Spacing Alias", undoManager: undoManager) { spec in
            spec.semantic.spacing.removeAll { $0.name == name }
        }
    }

    private func rename(old: String, new: String) {
        guard old != new else {
            return
        }
        document.edit(actionName: "Rename Spacing Alias", undoManager: undoManager) { spec in
            if let index = spec.semantic.spacing.firstIndex(where: { $0.name == old }) {
                spec.semantic.spacing[index].name = new
            }
            spec.rewriteAllReferences(
                from: .semantic("spacing", old),
                to: .semantic("spacing", new)
            )
        }
    }

    private func updateReference(name: String, newRef: TokenRef) {
        document.edit(actionName: "Edit Spacing Alias", undoManager: undoManager) { spec in
            if let index = spec.semantic.spacing.firstIndex(where: { $0.name == name }) {
                spec.semantic.spacing[index].reference = newRef
            }
        }
    }
}

// MARK: - Shared alias row

struct AliasRow: View {

    let name: String
    let reference: TokenRef
    let candidates: [PrimitiveReferencePicker.Candidate]
    let referenceBuilder: (String) -> TokenRef
    let resolvedLabel: String
    let onRenameCommit: (String) -> Void
    let onReferenceCommit: (TokenRef) -> Void
    let onDelete: () -> Void

    private var nameIsValid: Bool {
        KebabCase.isValid(name)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .trailing) {
                CommitOnDefocusTextField(
                    placeholder: "name",
                    source: name,
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

            PrimitiveReferencePicker(
                currentReference: reference,
                candidates: candidates,
                onCommit: onReferenceCommit,
                referenceBuilder: referenceBuilder
            )

            Spacer(minLength: 8)

            Text(resolvedLabel)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(resolvedLabel == "unresolved" ? .orange : .secondary)
        }
        .padding(.vertical, 7)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
