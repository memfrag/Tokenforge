//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// A snapshot of what files currently live inside a document's `Assets/`
/// subtree. Used by the Fonts picker (in Primitives → Typography) and the
/// eventual icon pickers to enumerate author-dropped content without
/// touching the filesystem every frame.
///
/// The manifest is rebuilt whenever the document's `FileWrapper` changes —
/// on initial read, and (optionally) after a save — so new drops show up
/// after a reopen cycle.
///
nonisolated struct AssetManifest: Equatable, Sendable {

    /// Filenames of `.ttf` / `.otf` files in `Assets/Fonts/`. Sorted.
    var fontFilenames: [String]

    /// Filenames of `.png` / `.pdf` files in `Assets/Icons/`. Sorted.
    var iconFilenames: [String]

    static let empty = AssetManifest(fontFilenames: [], iconFilenames: [])

    // MARK: - Extraction

    /// Walks a document-bundle `FileWrapper` and pulls out the filenames
    /// under `Assets/Fonts/` and `Assets/Icons/`. Silently ignores any
    /// unexpected entries (the author may have dropped unrelated files in
    /// the Assets subtree; those are out of scope for the picker UI but
    /// survive round-trips via `TokenforgeDocument.fileWrapper(...)`).
    static func extract(from bundle: FileWrapper) -> AssetManifest {
        guard bundle.isDirectory,
              let assets = bundle.fileWrappers?[TokenforgeDocument.BundleLayout.assetsDirectory],
              assets.isDirectory,
              let assetsChildren = assets.fileWrappers else {
            return .empty
        }

        let fonts = directoryFilenames(
            from: assetsChildren[TokenforgeDocument.BundleLayout.fontsDirectory],
            allowedExtensions: ["ttf", "otf"]
        )

        let icons = directoryFilenames(
            from: assetsChildren[TokenforgeDocument.BundleLayout.iconsDirectory],
            allowedExtensions: ["png", "pdf", "svg"]
        )

        return AssetManifest(fontFilenames: fonts, iconFilenames: icons)
    }

    /// Helper that walks one `FileWrapper` directory, filters to a set of
    /// allowed extensions (case-insensitive), and returns sorted filenames.
    private static func directoryFilenames(
        from wrapper: FileWrapper?,
        allowedExtensions: Set<String>
    ) -> [String] {
        guard let wrapper, wrapper.isDirectory, let children = wrapper.fileWrappers else {
            return []
        }
        var names: [String] = []
        for (name, child) in children where child.isRegularFile {
            let ext = (name as NSString).pathExtension.lowercased()
            if allowedExtensions.contains(ext) {
                names.append(name)
            }
        }
        return names.sorted()
    }
}

// MARK: - Font data extraction

nonisolated extension AssetManifest {

    /// Returns the raw font file bytes keyed by filename. Used by
    /// `FontRegistry` at document-open time so each `.ttf` / `.otf` can be
    /// registered with Core Text in one pass.
    static func fontData(from bundle: FileWrapper) -> [String: Data] {
        guard bundle.isDirectory,
              let assets = bundle.fileWrappers?[TokenforgeDocument.BundleLayout.assetsDirectory],
              assets.isDirectory,
              let assetsChildren = assets.fileWrappers,
              let fonts = assetsChildren[TokenforgeDocument.BundleLayout.fontsDirectory],
              fonts.isDirectory,
              let fontsChildren = fonts.fileWrappers else {
            return [:]
        }
        var data: [String: Data] = [:]
        for (name, child) in fontsChildren where child.isRegularFile {
            let ext = (name as NSString).pathExtension.lowercased()
            guard ext == "ttf" || ext == "otf" else {
                continue
            }
            if let bytes = child.regularFileContents {
                data[name] = bytes
            }
        }
        return data
    }
}
