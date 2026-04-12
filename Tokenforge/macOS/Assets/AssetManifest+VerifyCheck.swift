//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import os

#if DEBUG

extension AssetManifest {

    /// Launch-time smoke test. Builds a synthetic document-bundle
    /// `FileWrapper` with one fake font and one fake icon file inside
    /// `Assets/Fonts/` and `Assets/Icons/`, then runs `AssetManifest.extract`
    /// and asserts both filenames come back.
    ///
    /// Uses placeholder bytes — the font isn't actually registrable — so
    /// it validates the enumeration path only, not Core Text integration.
    /// The font-registration path is exercised the first time a real
    /// `.tokenforge` document containing real `.ttf`/`.otf` files is
    /// opened.
    ///
    static func verifyManifestExtraction() {
        let logger = Logger(subsystem: "io.apparata.Tokenforge", category: "AssetManifest")

        let fontsWrapper = FileWrapper(directoryWithFileWrappers: [
            "SFPro-Placeholder.ttf": FileWrapper(regularFileWithContents: Data(count: 64)),
            "README.txt": FileWrapper(regularFileWithContents: Data("ignored".utf8))
        ])
        fontsWrapper.preferredFilename = TokenforgeDocument.BundleLayout.fontsDirectory

        let iconsWrapper = FileWrapper(directoryWithFileWrappers: [
            "star.pdf": FileWrapper(regularFileWithContents: Data(count: 32)),
            "heart.png": FileWrapper(regularFileWithContents: Data(count: 32))
        ])
        iconsWrapper.preferredFilename = TokenforgeDocument.BundleLayout.iconsDirectory

        let assetsWrapper = FileWrapper(directoryWithFileWrappers: [
            TokenforgeDocument.BundleLayout.fontsDirectory: fontsWrapper,
            TokenforgeDocument.BundleLayout.iconsDirectory: iconsWrapper
        ])
        assetsWrapper.preferredFilename = TokenforgeDocument.BundleLayout.assetsDirectory

        let specWrapper = FileWrapper(regularFileWithContents: Data("{}".utf8))
        specWrapper.preferredFilename = TokenforgeDocument.BundleLayout.specFilename

        let root = FileWrapper(directoryWithFileWrappers: [:])
        root.addFileWrapper(specWrapper)
        root.addFileWrapper(assetsWrapper)

        let manifest = AssetManifest.extract(from: root)

        guard manifest.fontFilenames == ["SFPro-Placeholder.ttf"] else {
            assertionFailure("AssetManifest dropped or misread font filenames: \(manifest.fontFilenames)")
            return
        }
        guard manifest.iconFilenames == ["heart.png", "star.pdf"] else {
            assertionFailure("AssetManifest dropped or misread icon filenames: \(manifest.iconFilenames)")
            return
        }

        let fontData = AssetManifest.fontData(from: root)
        guard fontData.keys.contains("SFPro-Placeholder.ttf"), fontData["SFPro-Placeholder.ttf"]?.count == 64 else {
            assertionFailure("AssetManifest.fontData did not return the synthetic blob.")
            return
        }

        logger.info("""
            AssetManifest extraction verified: \
            \(manifest.fontFilenames.count, privacy: .public) font(s), \
            \(manifest.iconFilenames.count, privacy: .public) icon(s).
            """)
    }
}

#endif
