//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct IconsPane: View {

    @Bindable var document: TokenforgeDocument

    @Environment(\.undoManager) private var undoManager

    @State private var isDropTargeted: Bool = false

    private static let allowedExtensions: Set<String> = ["png", "pdf", "svg"]

    private var sortedFilenames: [String] {
        document.iconData.keys.sorted()
    }

    var body: some View {
        Pane {
            VStack(spacing: 0) {
                PaneHeader(
                    title: "Icons",
                    subtitle: "Curate SF Symbols and drop PNG, PDF, or SVG files to bundle with the document."
                ) {
                    Button {
                        chooseFiles()
                    } label: {
                        Label("Add Files…", systemImage: "plus")
                            .labelStyle(.titleAndIcon)
                    }
                    .controlSize(.regular)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        SFSymbolsSection(document: document, undoManager: undoManager)
                        filesSection
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                    handleDrop(providers: providers)
                }
                .overlay(AssetDropOverlay(isTargeted: isDropTargeted, prompt: "Drop to add"))
            }
        }
        .navigationTitle("Icons")
    }

    @ViewBuilder
    private var filesSection: some View {
        SectionCard(title: "Files", aside: filesAside) {
            Button {
                chooseFiles()
            } label: {
                Label("Add", systemImage: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(Color.accentColor)
        } content: {
            if sortedFilenames.isEmpty {
                filesEmptyState
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 140, maximum: 200), spacing: 16)],
                    alignment: .leading,
                    spacing: 16
                ) {
                    ForEach(sortedFilenames, id: \.self) { filename in
                        if let data = document.iconData[filename] {
                            IconCard(
                                filename: filename,
                                data: data,
                                onRename: { new in rename(old: filename, new: new) },
                                onDelete: { delete(filename: filename) },
                                onReveal: { reveal(filename: filename) }
                            )
                        }
                    }
                }
            }
        }
    }

    private var filesAside: String {
        let count = sortedFilenames.count
        return "\(count) file\(count == 1 ? "" : "s")"
    }

    private var filesEmptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(.tertiary)
            Text("No icon files yet")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Drop PNG, PDF, or SVG files anywhere in this pane, or use the Add Files… button above.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Drop & pick

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        AssetDropCoordinator.handleDrop(
            providers: providers,
            allowedExtensions: Self.allowedExtensions
        ) { dropped in
            guard !dropped.isEmpty else {
                return
            }
            addFiles(dropped)
        }
    }

    private func chooseFiles() {
        let panel = NSOpenPanel()
        panel.title = "Add Icons"
        panel.prompt = "Add"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.png, .pdf, .svg]
        guard panel.runModal() == .OK else {
            return
        }
        var collected: [String: Data] = [:]
        for url in panel.urls {
            let filename = url.lastPathComponent
            let ext = (filename as NSString).pathExtension.lowercased()
            guard Self.allowedExtensions.contains(ext) else {
                continue
            }
            if let bytes = try? Data(contentsOf: url) {
                collected[filename] = bytes
            }
        }
        if !collected.isEmpty {
            addFiles(collected)
        }
    }

    // MARK: - Mutations

    private func addFiles(_ files: [String: Data]) {
        document.editAssets(actionName: "Add Icon", undoManager: undoManager) { draft in
            let existingNames = Set(draft.iconData.keys)
            var existing = existingNames
            for (filename, data) in files.sorted(by: { $0.key < $1.key }) {
                let unique = uniqueFilename(filename, amongst: existing)
                draft.iconData[unique] = data
                existing.insert(unique)
            }
        }
    }

    private func delete(filename: String) {
        document.editAssets(actionName: "Delete Icon", undoManager: undoManager) { draft in
            draft.iconData.removeValue(forKey: filename)
        }
    }

    private func rename(old: String, new: String) {
        let trimmed = new.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != old else {
            return
        }
        // Preserve the original extension — authors shouldn't be able to
        // rename a PNG into a PDF via the text field.
        let oldExt = (old as NSString).pathExtension
        let newExt = (trimmed as NSString).pathExtension
        let effective: String
        if newExt.lowercased() == oldExt.lowercased() {
            effective = trimmed
        } else {
            let baseName = (trimmed as NSString).deletingPathExtension
            effective = oldExt.isEmpty ? baseName : "\(baseName).\(oldExt)"
        }
        guard effective != old else {
            return
        }
        document.editAssets(actionName: "Rename Icon", undoManager: undoManager) { draft in
            guard let data = draft.iconData[old] else {
                return
            }
            if draft.iconData[effective] != nil {
                // Refuse collisions.
                return
            }
            draft.iconData.removeValue(forKey: old)
            draft.iconData[effective] = data
        }
    }

    private func reveal(filename: String) {
        // The document's assets live inside the .tokenforge bundle on
        // disk. We can't reveal an in-memory-only icon; for now, save the
        // icon's bytes to a temp file and reveal that, so the user can
        // drag the temp into any other app.
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("tokenforge-icon-\(UUID().uuidString)-\(filename)")
        guard let data = document.iconData[filename] else {
            return
        }
        do {
            try data.write(to: tempURL, options: [.atomic])
            NSWorkspace.shared.activateFileViewerSelecting([tempURL])
        } catch {
            NSSound.beep()
        }
    }
}

// MARK: - Card

private struct IconCard: View {

    let filename: String
    let data: Data
    let onRename: (String) -> Void
    let onDelete: () -> Void
    let onReveal: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            thumbnail
                .frame(maxWidth: .infinity)
                .frame(height: 90)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(nsColor: .textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.separator, lineWidth: 0.5)
                )

            CommitOnDefocusTextField(
                placeholder: "filename",
                source: filename,
                font: .system(size: 11.5, weight: .medium),
                alignment: .center,
                onCommit: onRename
            )
            .frame(maxWidth: .infinity)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor).opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.separator, lineWidth: 0.5)
        )
        .contextMenu {
            Button {
                onReveal()
            } label: {
                Label("Reveal Copy in Finder", systemImage: "folder")
            }
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .padding(12)
        } else {
            VStack(spacing: 4) {
                Image(systemName: "questionmark.square.dashed")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(.tertiary)
                Text((filename as NSString).pathExtension.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
