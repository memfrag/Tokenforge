//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// A design system spec document.
///
/// Backed by a `.tokenforge` **package bundle** on disk containing:
///
/// ```
/// MySystem.tokenforge/
/// ├── spec.json            ← canonical TokenforgeSpec
/// └── Assets/
///     ├── Fonts/           ← custom font files (.ttf / .otf)
///     └── Icons/           ← custom icon files (.png / .pdf)
/// ```
///
/// The directory is always pre-created — even on a fresh document with no
/// custom assets — so authors can drop files in at any time without worrying
/// about structure.
///
@Observable
final class TokenforgeDocument: ReferenceFileDocument, @unchecked Sendable {

    // `@unchecked Sendable` is deliberate. `@Observable` synthesizes a
    // mutable backing store for `spec`, which trips Swift 6's strict
    // Sendable check for the `ReferenceFileDocument`-inferred conformance.
    // The class is actually safe:
    //
    // - All mutations to `spec` go through `TokenforgeDocument.edit(...)`
    //   in `TokenforgeDocument+Undo.swift`, which is `@MainActor`-isolated.
    // - The `nonisolated init(configuration:)` path reads `spec.json` from
    //   its `configuration.file` parameter and assigns to `self.spec`
    //   exactly once during construction, before the instance is visible
    //   to any other thread.
    // - The `nonisolated fileWrapper(snapshot:configuration:)` path
    //   operates only on the `snapshot` parameter value, never on
    //   `self.spec` directly.
    // - Font registration from background reads hops to `@MainActor` via
    //   `Task { @MainActor in FontRegistry.register(...) }` before
    //   touching process-wide state.
    //
    // The compiler can't verify this through the macro-generated backing
    // store, so we assert it manually.

    // MARK: - Bundle layout constants

    enum BundleLayout {
        static let specFilename = "spec.json"
        static let assetsDirectory = "Assets"
        static let fontsDirectory = "Fonts"
        static let iconsDirectory = "Icons"
    }

    // MARK: - Document type

    nonisolated static let readableContentTypes: [UTType] = [.tokenforgeDocument]
    nonisolated static let writableContentTypes: [UTType] = [.tokenforgeDocument]

    // MARK: - State

    /// The in-memory spec. All pane editors bind to fields on this value.
    var spec: TokenforgeSpec

    /// Raw bytes of every `.ttf` / `.otf` font file the author has dropped
    /// into the document's `Assets/Fonts/` subtree. Keyed by filename
    /// (with extension). Part of the save snapshot, so SwiftUI marks the
    /// document dirty whenever the dictionary changes.
    var fontData: [String: Data] = [:]

    /// Raw bytes of every icon file the author has dropped into the
    /// document's `Assets/Icons/` subtree. Keyed by filename (with
    /// extension). Part of the save snapshot.
    var iconData: [String: Data] = [:]

    /// Compatibility accessor for the per-pane inspector summary. Derived
    /// from `fontData` / `iconData` on each read so it always reflects the
    /// current asset state.
    var manifest: AssetManifest {
        AssetManifest(
            fontFilenames: fontData.keys.sorted(),
            iconFilenames: iconData.keys.sorted()
        )
    }

    // MARK: - Init

    /// Creates a new untitled document seeded from `DefaultSpec.json`.
    init() {
        do {
            self.spec = try TokenforgeSpec.loadDefaultFromBundle()
        } catch {
            assertionFailure("Failed to load DefaultSpec.json for new document: \(error)")
            self.spec = TokenforgeDocument.emergencyEmptySpec
        }
        self.fontData = [:]
        self.iconData = [:]
    }

    /// Reads an existing `.tokenforge` bundle from disk.
    nonisolated init(configuration: ReadConfiguration) throws {
        let decodedSpec = try Self.decodeSpec(fromBundleWrapper: configuration.file)
        self.spec = decodedSpec

        let extractedFonts = Self.extractFontData(from: configuration.file)
        let extractedIcons = Self.extractIconData(from: configuration.file)
        self.fontData = extractedFonts
        self.iconData = extractedIcons

        // Hop to main actor for Core Text registration, which touches
        // process-wide state via `FontRegistry`.
        Task { @MainActor in
            FontRegistry.register(extractedFonts)
        }
    }

    /// Extracts and decodes `spec.json` from a directory `FileWrapper`
    /// representing a `.tokenforge` bundle. Shared between the SwiftUI read
    /// path and the DEBUG bundle-layout check.
    nonisolated static func decodeSpec(fromBundleWrapper root: FileWrapper) throws -> TokenforgeSpec {
        guard root.isDirectory else {
            throw CocoaError(.fileReadCorruptFile)
        }
        guard let children = root.fileWrappers,
              let specWrapper = children[BundleLayout.specFilename],
              let data = specWrapper.regularFileContents else {
            throw CocoaError(.fileReadNoSuchFile)
        }
        return try TokenforgeSpec.decode(from: data)
    }

    // MARK: - Asset extraction

    /// Walks `<root>/Assets/Fonts/` and returns every `.ttf`/`.otf` file's
    /// bytes keyed by filename. Returns an empty dictionary if any level of
    /// the subtree is missing — existing documents created before the
    /// asset panes shipped still open cleanly.
    nonisolated static func extractFontData(from root: FileWrapper) -> [String: Data] {
        guard root.isDirectory,
              let assets = root.fileWrappers?[BundleLayout.assetsDirectory],
              assets.isDirectory,
              let fonts = assets.fileWrappers?[BundleLayout.fontsDirectory],
              fonts.isDirectory,
              let children = fonts.fileWrappers else {
            return [:]
        }
        var result: [String: Data] = [:]
        for (name, child) in children where child.isRegularFile {
            let ext = (name as NSString).pathExtension.lowercased()
            guard ext == "ttf" || ext == "otf" else {
                continue
            }
            if let bytes = child.regularFileContents {
                result[name] = bytes
            }
        }
        return result
    }

    /// Walks `<root>/Assets/Icons/` and returns every `.png`/`.pdf`/`.svg`
    /// file's bytes keyed by filename.
    nonisolated static func extractIconData(from root: FileWrapper) -> [String: Data] {
        guard root.isDirectory,
              let assets = root.fileWrappers?[BundleLayout.assetsDirectory],
              assets.isDirectory,
              let icons = assets.fileWrappers?[BundleLayout.iconsDirectory],
              icons.isDirectory,
              let children = icons.fileWrappers else {
            return [:]
        }
        var result: [String: Data] = [:]
        for (name, child) in children where child.isRegularFile {
            let ext = (name as NSString).pathExtension.lowercased()
            guard ["png", "pdf", "svg"].contains(ext) else {
                continue
            }
            if let bytes = child.regularFileContents {
                result[name] = bytes
            }
        }
        return result
    }

    // MARK: - Snapshot & write

    /// Returns a snapshot of the full document state. `ReferenceFileDocument`
    /// compares successive snapshots to decide when to mark the document
    /// dirty, so the snapshot must include every piece of user-visible
    /// state: spec, font data, icon data.
    func snapshot(contentType: UTType) throws -> TokenforgeSnapshot {
        TokenforgeSnapshot(spec: spec, fontData: fontData, iconData: iconData)
    }

    /// Writes the snapshot as a directory `FileWrapper` representing the
    /// `.tokenforge` bundle. The Assets subtree is rebuilt from scratch
    /// from the snapshot's dictionaries; unknown files previously in
    /// `Assets/` are not preserved.
    nonisolated func fileWrapper(snapshot: TokenforgeSnapshot, configuration: WriteConfiguration) throws -> FileWrapper {
        try Self.makeBundleFileWrapper(from: snapshot, existing: configuration.existingFile)
    }

    // MARK: - Bundle construction

    /// Builds a directory `FileWrapper` for `snapshot`, populating the
    /// `Assets/Fonts/` and `Assets/Icons/` subtrees from the snapshot's
    /// dictionaries. The `existing` parameter is no longer consulted —
    /// asset state lives on the document, so the directory is rebuilt
    /// from scratch every save.
    nonisolated static func makeBundleFileWrapper(
        from snapshot: TokenforgeSnapshot,
        existing: FileWrapper?
    ) throws -> FileWrapper {

        let specData = try snapshot.spec.encodeJSON()
        let specWrapper = FileWrapper(regularFileWithContents: specData)
        specWrapper.preferredFilename = BundleLayout.specFilename

        let fontsWrapper = buildAssetDirectoryWrapper(
            from: snapshot.fontData,
            directoryName: BundleLayout.fontsDirectory
        )
        let iconsWrapper = buildAssetDirectoryWrapper(
            from: snapshot.iconData,
            directoryName: BundleLayout.iconsDirectory
        )

        let assetsWrapper = FileWrapper(directoryWithFileWrappers: [
            BundleLayout.fontsDirectory: fontsWrapper,
            BundleLayout.iconsDirectory: iconsWrapper
        ])
        assetsWrapper.preferredFilename = BundleLayout.assetsDirectory

        let root = FileWrapper(directoryWithFileWrappers: [:])
        root.addFileWrapper(specWrapper)
        root.addFileWrapper(assetsWrapper)
        return root
    }

    /// Builds a directory `FileWrapper` whose children are regular-file
    /// wrappers, one per (filename, data) pair in `entries`.
    nonisolated private static func buildAssetDirectoryWrapper(
        from entries: [String: Data],
        directoryName: String
    ) -> FileWrapper {
        var children: [String: FileWrapper] = [:]
        for (filename, bytes) in entries {
            let file = FileWrapper(regularFileWithContents: bytes)
            file.preferredFilename = filename
            children[filename] = file
        }
        let directory = FileWrapper(directoryWithFileWrappers: children)
        directory.preferredFilename = directoryName
        return directory
    }

    /// Retained as a compatibility stub. The new path always rebuilds the
    /// Assets subtree from `fontData`/`iconData`; no in-place mutation of
    /// an existing wrapper is needed.
    nonisolated private static func ensureAssetsSubdirectories(in assets: FileWrapper) {
        var children = assets.fileWrappers ?? [:]
        if children[BundleLayout.fontsDirectory] == nil {
            let fonts = FileWrapper(directoryWithFileWrappers: [:])
            fonts.preferredFilename = BundleLayout.fontsDirectory
            assets.addFileWrapper(fonts)
            children[BundleLayout.fontsDirectory] = fonts
        }
        if children[BundleLayout.iconsDirectory] == nil {
            let icons = FileWrapper(directoryWithFileWrappers: [:])
            icons.preferredFilename = BundleLayout.iconsDirectory
            assets.addFileWrapper(icons)
        }
    }

    // MARK: - Fallback

    /// Used only if `DefaultSpec.json` fails to load. The DEBUG round-trip check
    /// will already have crashed in that case; this keeps release builds limping
    /// along with a structurally valid (but empty) spec instead of a hard crash.
    private static var emergencyEmptySpec: TokenforgeSpec {
        TokenforgeSpec(
            schemaVersion: SchemaVersion.current,
            meta: SpecMeta(name: "Untitled", version: "0.0.0", summary: "", author: ""),
            primitives: Primitives(
                color: [], spacing: [], radius: [],
                typography: TypographyPrimitives(
                    fontFamilies: [], fontSizes: [], fontWeights: [], lineHeights: []
                ),
                elevation: [], stroke: [],
                motion: MotionPrimitives(durations: [], curves: [])
            ),
            semantic: SemanticTokens(color: [], type: [], spacing: [], radius: []),
            hierarchy: HierarchyRules(
                screenStructure: [], maxPrimaryActionsPerArea: 1, rules: [],
                emphasisScale: [], typeEmphasis: []
            ),
            components: Self.emergencyComponentSet,
            accessibility: AccessibilityRules(
                minTapTargetPoints: 44, minContrast: "WCAG AA",
                dynamicTypeSupport: true, notes: []
            ),
            llmContract: LLMContractOverrides(rolePrompt: "", extraHardRules: [], notes: ""),
            examples: ExtraExamples(items: []),
            lastExportBookmarkID: nil
        )
    }

    /// Emergency fallback component set — every field filled with a single
    /// placeholder ref. Never used on the happy path; only constructed when
    /// `DefaultSpec.json` fails to load. Routes through the shared
    /// `ComponentSet.placeholder(...)` factory so the DTCG importer and the
    /// emergency-fallback path produce the same shape.
    private static var emergencyComponentSet: ComponentSet {
        let placeholder = TokenRef(rawValue: "{primitives.color.placeholder}")
        return ComponentSet.placeholder(
            color: placeholder,
            spacing: placeholder,
            radius: placeholder,
            textStyle: placeholder
        )
    }
}
