//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

struct SemanticColorSection: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var entries: [SemanticColor] {
        document.spec.semantic.color
    }

    private var resolver: TokenResolver {
        TokenResolver(spec: document.spec)
    }

    private var colorCandidates: [PrimitiveReferencePicker.Candidate] {
        document.spec.primitives.color.map { primitive in
            PrimitiveReferencePicker.Candidate(
                name: primitive.name,
                preview: .color(hex: primitive.hex)
            )
        }
    }

    var body: some View {
        SectionCard(title: "Color", aside: asideText) {
            AddPrimitiveButton(action: addColor)
        } content: {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(entries) { entry in
                    ColorRow(
                        entry: entry,
                        candidates: colorCandidates,
                        resolvedLight: resolveHex(entry.light, appearance: .light),
                        resolvedDark: resolveHex(entry.dark, appearance: .dark),
                        onRenameCommit: { new in rename(old: entry.name, new: new) },
                        onLightCommit: { ref in updateLight(name: entry.name, newRef: ref) },
                        onDarkCommit: { ref in updateDark(name: entry.name, newRef: ref) },
                        onDelete: { delete(name: entry.name) }
                    )
                    if entry.id != entries.last?.id {
                        Divider().opacity(0.4)
                    }
                }
            }
        }
    }

    // MARK: - Derived

    private var asideText: String {
        let total = entries.count
        let invalidNames = entries.filter { !KebabCase.isValid($0.name) }.count
        let unresolved = entries.filter {
            resolveHex($0.light, appearance: .light) == nil || resolveHex($0.dark, appearance: .dark) == nil
        }.count
        let warnings = invalidNames + unresolved
        if warnings > 0 {
            return "\(total) values · \(warnings) warning\(warnings == 1 ? "" : "s")"
        }
        return "\(total) values"
    }

    private func resolveHex(_ ref: TokenRef, appearance: TokenResolver.Appearance) -> String? {
        if case .color(let hex) = resolver.resolve(ref, appearance: appearance) {
            return hex
        }
        return nil
    }

    // MARK: - Mutations

    private func addColor() {
        document.edit(actionName: "Add Semantic Color", undoManager: undoManager) { spec in
            let baseName = "new.color"
            var candidate = baseName
            var suffix = 1
            let existing = Set(spec.semantic.color.map(\.name))
            while existing.contains(candidate) {
                suffix += 1
                candidate = "\(baseName).\(suffix)"
            }
            let fallback = spec.primitives.color.first?.name ?? ""
            let ref = TokenRef.primitive("color", fallback)
            spec.semantic.color.append(SemanticColor(name: candidate, light: ref, dark: ref))
        }
    }

    private func delete(name: String) {
        document.edit(actionName: "Delete Semantic Color", undoManager: undoManager) { spec in
            spec.semantic.color.removeAll { $0.name == name }
        }
    }

    private func rename(old: String, new: String) {
        guard old != new else {
            return
        }
        document.edit(actionName: "Rename Semantic Color", undoManager: undoManager) { spec in
            if let index = spec.semantic.color.firstIndex(where: { $0.name == old }) {
                spec.semantic.color[index].name = new
            }
            spec.rewriteAllReferences(
                from: .semantic("color", old),
                to: .semantic("color", new)
            )
        }
    }

    private func updateLight(name: String, newRef: TokenRef) {
        document.edit(actionName: "Edit Semantic Color", undoManager: undoManager) { spec in
            if let index = spec.semantic.color.firstIndex(where: { $0.name == name }) {
                spec.semantic.color[index].light = newRef
            }
        }
    }

    private func updateDark(name: String, newRef: TokenRef) {
        document.edit(actionName: "Edit Semantic Color", undoManager: undoManager) { spec in
            if let index = spec.semantic.color.firstIndex(where: { $0.name == name }) {
                spec.semantic.color[index].dark = newRef
            }
        }
    }
}

// MARK: - Row

private struct ColorRow: View {

    let entry: SemanticColor
    let candidates: [PrimitiveReferencePicker.Candidate]
    let resolvedLight: String?
    let resolvedDark: String?
    let onRenameCommit: (String) -> Void
    let onLightCommit: (TokenRef) -> Void
    let onDarkCommit: (TokenRef) -> Void
    let onDelete: () -> Void

    private var nameIsValid: Bool {
        KebabCase.isValid(entry.name)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Dual-swatch preview
            DualSwatch(lightHex: resolvedLight, darkHex: resolvedDark)

            // Name field
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
                .frame(height: 16)
                .overlay(Color.primary.opacity(0.08))

            // Light picker
            VStack(alignment: .leading, spacing: 2) {
                Text("LIGHT")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(.tertiary)
                PrimitiveReferencePicker(
                    currentReference: entry.light,
                    candidates: candidates,
                    onCommit: onLightCommit,
                    referenceBuilder: { TokenRef.primitive("color", $0) }
                )
            }

            // Dark picker
            VStack(alignment: .leading, spacing: 2) {
                Text("DARK")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(.tertiary)
                PrimitiveReferencePicker(
                    currentReference: entry.dark,
                    candidates: candidates,
                    onCommit: onDarkCommit,
                    referenceBuilder: { TokenRef.primitive("color", $0) }
                )
            }

            Spacer(minLength: 8)

            // Resolved hex display
            VStack(alignment: .trailing, spacing: 2) {
                Text(resolvedLight ?? "unresolved")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(resolvedLight == nil ? .orange : .secondary)
                Text(resolvedDark ?? "unresolved")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(resolvedDark == nil ? .orange : .secondary)
            }
        }
        .padding(.vertical, 8)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Dual swatch

private struct DualSwatch: View {

    let lightHex: String?
    let darkHex: String?

    var body: some View {
        ZStack {
            // Light half (bottom-left)
            lightColor
                .clipShape(
                    Path { path in
                        path.move(to: .zero)
                        path.addLine(to: CGPoint(x: 36, y: 0))
                        path.addLine(to: CGPoint(x: 0, y: 28))
                        path.closeSubpath()
                    }
                )
            // Dark half (top-right)
            darkColor
                .clipShape(
                    Path { path in
                        path.move(to: CGPoint(x: 36, y: 0))
                        path.addLine(to: CGPoint(x: 36, y: 28))
                        path.addLine(to: CGPoint(x: 0, y: 28))
                        path.closeSubpath()
                    }
                )
        }
        .frame(width: 36, height: 28)
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(.separator, lineWidth: 0.5)
        )
    }

    private var lightColor: Color {
        lightHex.flatMap { Color(hex: $0) } ?? Color.gray.opacity(0.3)
    }

    private var darkColor: Color {
        darkHex.flatMap { Color(hex: $0) } ?? Color.gray.opacity(0.5)
    }
}
