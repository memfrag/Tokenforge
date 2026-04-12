//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct SemanticRadiusSection: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var entries: [SemanticAlias] {
        document.spec.semantic.radius
    }

    private var resolver: TokenResolver {
        TokenResolver(spec: document.spec)
    }

    private var radiusCandidates: [PrimitiveReferencePicker.Candidate] {
        document.spec.primitives.radius.map { primitive in
            PrimitiveReferencePicker.Candidate(
                name: primitive.name,
                preview: .points(primitive.points)
            )
        }
    }

    var body: some View {
        SectionCard(title: "Radius", aside: "\(entries.count) aliases") {
            AddPrimitiveButton(action: addAlias)
        } content: {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(entries) { entry in
                    AliasRow(
                        name: entry.name,
                        reference: entry.reference,
                        candidates: radiusCandidates,
                        referenceBuilder: { TokenRef.primitive("radius", $0) },
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
            return value.rounded() == value
                ? String(format: "%.0f pt", value)
                : String(format: "%.2f pt", value)
        }
        return "unresolved"
    }

    // MARK: - Mutations

    private func addAlias() {
        document.edit(actionName: "Add Radius Alias", undoManager: undoManager) { spec in
            let baseName = "new-alias"
            var candidate = baseName
            var suffix = 1
            let existing = Set(spec.semantic.radius.map(\.name))
            while existing.contains(candidate) {
                suffix += 1
                candidate = "\(baseName)-\(suffix)"
            }
            let fallback = spec.primitives.radius.first?.name ?? ""
            spec.semantic.radius.append(
                SemanticAlias(name: candidate, reference: .primitive("radius", fallback))
            )
        }
    }

    private func delete(name: String) {
        document.edit(actionName: "Delete Radius Alias", undoManager: undoManager) { spec in
            spec.semantic.radius.removeAll { $0.name == name }
        }
    }

    private func rename(old: String, new: String) {
        guard old != new else {
            return
        }
        document.edit(actionName: "Rename Radius Alias", undoManager: undoManager) { spec in
            if let index = spec.semantic.radius.firstIndex(where: { $0.name == old }) {
                spec.semantic.radius[index].name = new
            }
            spec.rewriteAllReferences(
                from: .semantic("radius", old),
                to: .semantic("radius", new)
            )
        }
    }

    private func updateReference(name: String, newRef: TokenRef) {
        document.edit(actionName: "Edit Radius Alias", undoManager: undoManager) { spec in
            if let index = spec.semantic.radius.firstIndex(where: { $0.name == name }) {
                spec.semantic.radius[index].reference = newRef
            }
        }
    }
}
