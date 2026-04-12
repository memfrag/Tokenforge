//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// Editor for `spec.meta` (name, version, summary, author).
///
/// These four fields are read in lots of places — sidebar footer, info
/// inspector, LLM contract header, export folder slug — but until now they
/// were not editable anywhere in the UI. This section makes them so.
///
/// Each field commits via `TokenforgeDocument.edit(...)` so edits become
/// undoable, and the multi-line summary uses `CommitOnDefocusTextField`'s
/// new vertical-axis support.
///
struct ContractMetaSection: View {

    @Bindable var document: TokenforgeDocument
    let undoManager: UndoManager?

    private var meta: SpecMeta {
        document.spec.meta
    }

    var body: some View {
        SectionCard(title: "Document") {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: 0) {
                MetaRow(label: "Name") {
                    CommitOnDefocusTextField(
                        placeholder: "Acme Design System",
                        source: meta.name,
                        font: .system(size: 13)
                    ) { new in
                        update { $0.name = new }
                    }
                }
                Divider().opacity(0.4)
                MetaRow(label: "Version") {
                    CommitOnDefocusTextField(
                        placeholder: "0.1.0",
                        source: meta.version,
                        font: .system(size: 13, design: .monospaced)
                    ) { new in
                        update { $0.version = new }
                    }
                    .frame(maxWidth: 180, alignment: .leading)
                }
                Divider().opacity(0.4)
                MetaRow(label: "Author") {
                    CommitOnDefocusTextField(
                        placeholder: "Author name",
                        source: meta.author,
                        font: .system(size: 13)
                    ) { new in
                        update { $0.author = new }
                    }
                }
                Divider().opacity(0.4)
                MetaRow(label: "Summary", alignTop: true) {
                    CommitOnDefocusTextField(
                        placeholder: "One paragraph for the LLM contract preamble.",
                        source: meta.summary,
                        font: .system(size: 13),
                        axis: .vertical,
                        lineLimit: 3...8
                    ) { new in
                        update { $0.summary = new }
                    }
                }
            }
        }
    }

    private func update(_ apply: (inout SpecMeta) -> Void) {
        document.edit(actionName: "Edit Document Meta", undoManager: undoManager) { spec in
            apply(&spec.meta)
        }
    }
}

/// Two-column row used by the meta editor: a fixed-width label on the left
/// and a flexible field on the right. Mirrors the form-row aesthetic in
/// the design exploration.
private struct MetaRow<Field: View>: View {

    let label: String
    let alignTop: Bool
    @ViewBuilder let field: () -> Field

    init(label: String, alignTop: Bool = false, @ViewBuilder field: @escaping () -> Field) {
        self.label = label
        self.alignTop = alignTop
        self.field = field
    }

    var body: some View {
        HStack(alignment: alignTop ? .top : .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
                .padding(.top, alignTop ? 7 : 0)
            field()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 7)
    }
}
