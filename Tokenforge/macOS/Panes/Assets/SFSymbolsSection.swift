//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import AppKit

/// Grid of SF Symbol references stored in `spec.iconSet.sfSymbols`. Sits
/// above the dropped-files grid in `IconsPane` so the author can curate
/// system glyphs alongside any bundled artwork.
///
/// Each card renders a live `Image(systemName:)` preview, an editable
/// name field, and an optional caption field. The name field validates
/// against `NSImage(systemSymbolName:)` so a typo like `heart.fll` shows
/// an inline warning instead of silently rendering nothing in the
/// generated app.
///
struct SFSymbolsSection: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var entries: [SFSymbolEntry] {
        document.spec.iconSet.sfSymbols
    }

    var body: some View {
        SectionCard(title: "SF Symbols", aside: asideText) {
            Button {
                addSymbol()
            } label: {
                Label("Add", systemImage: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(Color.accentColor)
        } content: {
            if entries.isEmpty {
                emptyState
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 148, maximum: 220), spacing: 10)],
                    alignment: .leading,
                    spacing: 10
                ) {
                    ForEach(entries) { entry in
                        SFSymbolCard(
                            entry: entry,
                            onRenameCommit: { newName in
                                rename(oldName: entry.name, newName: newName)
                            },
                            onCaptionCommit: { newCaption in
                                updateCaption(name: entry.name, newCaption: newCaption)
                            },
                            onDelete: {
                                delete(name: entry.name)
                            },
                            onCopyName: {
                                copyName(entry.name)
                            }
                        )
                    }
                }
            }
        }
    }

    private var asideText: String {
        let total = entries.count
        let invalid = entries.filter { !Self.symbolExists($0.name) }.count
        if invalid > 0 {
            return "\(total) symbol\(total == 1 ? "" : "s") · \(invalid) warning\(invalid == 1 ? "" : "s")"
        }
        return "\(total) symbol\(total == 1 ? "" : "s")"
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "star")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(.tertiary)
            Text("No SF Symbols yet")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Add SF Symbol names to expose system glyphs to the LLM contract.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Validation

    static func symbolExists(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return false
        }
        return NSImage(systemSymbolName: trimmed, accessibilityDescription: nil) != nil
    }

    // MARK: - Mutations

    private func addSymbol() {
        document.edit(actionName: "Add SF Symbol", undoManager: undoManager) { spec in
            let baseName = "star"
            var candidate = baseName
            var suffix = 1
            let existing = Set(spec.iconSet.sfSymbols.map(\.name))
            while existing.contains(candidate) {
                suffix += 1
                candidate = "\(baseName)-\(suffix)"
            }
            spec.iconSet.sfSymbols.append(SFSymbolEntry(name: candidate))
        }
    }

    private func delete(name: String) {
        document.edit(actionName: "Delete SF Symbol", undoManager: undoManager) { spec in
            spec.iconSet.sfSymbols.removeAll { $0.name == name }
        }
    }

    private func rename(oldName: String, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != oldName else {
            return
        }
        document.edit(actionName: "Rename SF Symbol", undoManager: undoManager) { spec in
            guard let index = spec.iconSet.sfSymbols.firstIndex(where: { $0.name == oldName }) else {
                return
            }
            if spec.iconSet.sfSymbols.contains(where: { $0.name == trimmed }) {
                return
            }
            spec.iconSet.sfSymbols[index].name = trimmed
        }
    }

    private func updateCaption(name: String, newCaption: String) {
        document.edit(actionName: "Edit SF Symbol Caption", undoManager: undoManager) { spec in
            guard let index = spec.iconSet.sfSymbols.firstIndex(where: { $0.name == name }) else {
                return
            }
            spec.iconSet.sfSymbols[index].caption = newCaption
        }
    }

    private func copyName(_ name: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(name, forType: .string)
    }
}

// MARK: - Card

private struct SFSymbolCard: View {

    let entry: SFSymbolEntry
    let onRenameCommit: (String) -> Void
    let onCaptionCommit: (String) -> Void
    let onDelete: () -> Void
    let onCopyName: () -> Void

    private var nameIsValid: Bool {
        SFSymbolsSection.symbolExists(entry.name)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if nameIsValid {
                        Image(systemName: entry.name)
                            .font(.system(size: 30, weight: .regular))
                            .foregroundStyle(.primary)
                    } else {
                        Image(systemName: "questionmark.square.dashed")
                            .font(.system(size: 30, weight: .regular))
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 64)

                if !nameIsValid {
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 14, height: 14)
                        .background(Circle().fill(.orange))
                        .overlay(Circle().stroke(Color(nsColor: .textBackgroundColor), lineWidth: 2))
                        .padding(6)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                CommitOnDefocusTextField(
                    placeholder: "symbol.name",
                    source: entry.name,
                    font: .system(size: 11.5, weight: .medium, design: .monospaced),
                    onCommit: onRenameCommit
                )
                CommitOnDefocusTextField(
                    placeholder: "caption (optional)",
                    source: entry.caption,
                    font: .system(size: 10.5),
                    onCommit: onCaptionCommit
                )
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(.separator)
                    .frame(height: 0.5)
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(nameIsValid ? Color.clear : .orange, lineWidth: 1.25)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.separator, lineWidth: 0.5)
                .opacity(nameIsValid ? 1 : 0)
        )
        .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
        .contextMenu {
            Button {
                onCopyName()
            } label: {
                Label("Copy Name", systemImage: "doc.on.doc")
            }
            Divider()
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
