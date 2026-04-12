//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct FontsPane: View {

    @Bindable var document: TokenforgeDocument

    @Environment(\.undoManager) private var undoManager

    @State private var isDropTargeted: Bool = false

    private static let allowedExtensions: Set<String> = ["ttf", "otf"]
    private static let sampleText = "The quick brown fox jumps over the lazy dog."

    private var sortedFilenames: [String] {
        document.fontData.keys.sorted()
    }

    var body: some View {
        Pane {
            VStack(spacing: 0) {
                PaneHeader(
                    title: "Fonts",
                    subtitle: "Drop TTF or OTF files to register them for the Preview pane."
                ) {
                    Button {
                        chooseFiles()
                    } label: {
                        Label("Add…", systemImage: "plus")
                            .labelStyle(.titleAndIcon)
                    }
                    .controlSize(.regular)
                }

                content
                    .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                        handleDrop(providers: providers)
                    }
            }
        }
        .navigationTitle("Fonts")
    }

    @ViewBuilder
    private var content: some View {
        if sortedFilenames.isEmpty {
            emptyState
                .overlay(AssetDropOverlay(isTargeted: isDropTargeted, prompt: "Drop fonts here"))
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(sortedFilenames, id: \.self) { filename in
                        FontCard(
                            filename: filename,
                            postScriptNames: FontRegistry.postScriptNames(forFilename: filename),
                            sampleText: Self.sampleText,
                            onRename: { new in rename(old: filename, new: new) },
                            onDelete: { delete(filename: filename) },
                            onReveal: { reveal(filename: filename) }
                        )
                    }
                }
                .padding(24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .overlay(AssetDropOverlay(isTargeted: isDropTargeted, prompt: "Drop to add"))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "textformat")
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(.tertiary)
            Text("No custom fonts")
                .font(.system(size: 15, weight: .semibold))
            Text("Drop TTF or OTF files anywhere in this pane, or use the Add… button above. Registered fonts become available to typography primitives and the Preview pane.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        panel.title = "Add Fonts"
        panel.prompt = "Add"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        if let ttf = UTType(filenameExtension: "ttf"), let otf = UTType(filenameExtension: "otf") {
            panel.allowedContentTypes = [ttf, otf]
        }
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
        // Register with CoreText first so the Fonts pane can show a live
        // sample as soon as the add is applied. Uniquification is based on
        // the undo-applied draft's final filenames, so register in a second
        // pass keyed by those names.
        document.editAssets(actionName: "Add Font", undoManager: undoManager) { draft in
            let existingNames = Set(draft.fontData.keys)
            var existing = existingNames
            var registerBatch: [String: Data] = [:]
            for (filename, data) in files.sorted(by: { $0.key < $1.key }) {
                let unique = uniqueFilename(filename, amongst: existing)
                draft.fontData[unique] = data
                existing.insert(unique)
                registerBatch[unique] = data
            }
            Task { @MainActor in
                FontRegistry.register(registerBatch)
            }
        }
    }

    private func delete(filename: String) {
        document.editAssets(actionName: "Delete Font", undoManager: undoManager) { draft in
            draft.fontData.removeValue(forKey: filename)
        }
    }

    private func rename(old: String, new: String) {
        let trimmed = new.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != old else {
            return
        }
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
        document.editAssets(actionName: "Rename Font", undoManager: undoManager) { draft in
            guard let data = draft.fontData[old] else {
                return
            }
            if draft.fontData[effective] != nil {
                return
            }
            draft.fontData.removeValue(forKey: old)
            draft.fontData[effective] = data
        }
    }

    private func reveal(filename: String) {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("tokenforge-font-\(UUID().uuidString)-\(filename)")
        guard let data = document.fontData[filename] else {
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

private struct FontCard: View {

    let filename: String
    let postScriptNames: [String]
    let sampleText: String
    let onRename: (String) -> Void
    let onDelete: () -> Void
    let onReveal: () -> Void

    private var primaryPostScriptName: String? {
        postScriptNames.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            Divider().opacity(0.4)
            samples
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor).opacity(0.5))
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

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                CommitOnDefocusTextField(
                    placeholder: "filename",
                    source: filename,
                    font: .system(size: 13, weight: .semibold, design: .monospaced),
                    onCommit: onRename
                )
                if postScriptNames.isEmpty {
                    Text("Not yet registered")
                        .font(.system(size: 10.5))
                        .foregroundStyle(.orange)
                } else {
                    Text(postScriptNames.joined(separator: " · "))
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var samples: some View {
        if let psName = primaryPostScriptName {
            VStack(alignment: .leading, spacing: 6) {
                Text(sampleText)
                    .font(Font.custom(psName, size: 28))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(sampleText)
                    .font(Font.custom(psName, size: 17))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(sampleText)
                    .font(Font.custom(psName, size: 13))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        } else {
            Text("No live sample: this font hasn't been registered with Core Text. Reopen the document, or drop the file again, to register it.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
    }
}
