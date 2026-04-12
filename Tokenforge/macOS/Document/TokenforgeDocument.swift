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
final class TokenforgeDocument: ReferenceFileDocument {

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

    /// Snapshot of the author-dropped assets (fonts, icons) in the
    /// document's bundle. Refreshed from the `FileWrapper` at open and
    /// whenever `fileWrapper(snapshot:configuration:)` runs with a
    /// previously-existing file.
    var manifest: AssetManifest = .empty

    // MARK: - Init

    /// Creates a new untitled document seeded from `DefaultSpec.json`.
    init() {
        do {
            self.spec = try TokenforgeSpec.loadDefaultFromBundle()
        } catch {
            assertionFailure("Failed to load DefaultSpec.json for new document: \(error)")
            self.spec = TokenforgeDocument.emergencyEmptySpec
        }
        self.manifest = .empty
    }

    /// Reads an existing `.tokenforge` bundle from disk.
    nonisolated init(configuration: ReadConfiguration) throws {
        let decodedSpec = try Self.decodeSpec(fromBundleWrapper: configuration.file)
        self.spec = decodedSpec

        // Extract the manifest off the background thread — pure value work.
        let extractedManifest = AssetManifest.extract(from: configuration.file)
        let fontData = AssetManifest.fontData(from: configuration.file)
        self.manifest = extractedManifest

        // Hop to main actor for Core Text registration, which touches
        // process-wide state via `FontRegistry`.
        Task { @MainActor in
            FontRegistry.register(fontData)
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

    // MARK: - Snapshot & write

    /// Returns a snapshot of the current spec. `ReferenceFileDocument` uses
    /// this so undo works correctly — the snapshot is the state "as of" the
    /// moment the save was initiated.
    func snapshot(contentType: UTType) throws -> TokenforgeSpec {
        spec
    }

    /// Writes the snapshot as a directory `FileWrapper` representing the
    /// `.tokenforge` bundle.
    nonisolated func fileWrapper(snapshot: TokenforgeSpec, configuration: WriteConfiguration) throws -> FileWrapper {
        try Self.makeBundleFileWrapper(from: snapshot, existing: configuration.existingFile)
    }

    // MARK: - Bundle construction

    /// Builds a directory `FileWrapper` for `snapshot`. If `existing` is
    /// provided (the document is being overwritten), any user-dropped
    /// `Assets/` subtree on disk is preserved — we only rewrite `spec.json`
    /// and ensure the `Assets/Fonts` and `Assets/Icons` directories exist.
    nonisolated static func makeBundleFileWrapper(
        from snapshot: TokenforgeSpec,
        existing: FileWrapper?
    ) throws -> FileWrapper {

        let specData = try snapshot.encodeJSON()
        let specWrapper = FileWrapper(regularFileWithContents: specData)
        specWrapper.preferredFilename = BundleLayout.specFilename

        // Preserve the existing Assets/ subtree on overwrite so author-dropped
        // fonts and icons are never destroyed by a save. If there is no existing
        // Assets wrapper (fresh document, or a legacy bundle that lacks it),
        // create an empty one.
        let assetsWrapper: FileWrapper
        if let existing, existing.isDirectory,
           let existingAssets = existing.fileWrappers?[BundleLayout.assetsDirectory],
           existingAssets.isDirectory {
            assetsWrapper = existingAssets
            ensureAssetsSubdirectories(in: assetsWrapper)
        } else {
            assetsWrapper = FileWrapper(directoryWithFileWrappers: [
                BundleLayout.fontsDirectory: FileWrapper(directoryWithFileWrappers: [:]),
                BundleLayout.iconsDirectory: FileWrapper(directoryWithFileWrappers: [:])
            ])
            assetsWrapper.preferredFilename = BundleLayout.assetsDirectory
        }

        let root = FileWrapper(directoryWithFileWrappers: [:])
        root.addFileWrapper(specWrapper)
        root.addFileWrapper(assetsWrapper)
        return root
    }

    /// Makes sure the Fonts and Icons subdirectories exist inside an existing
    /// `Assets/` wrapper, creating empty ones if they are missing.
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
