//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import os

#if DEBUG

extension TokenforgeDocument {

    /// At app launch in DEBUG, build a directory `FileWrapper` for a freshly-seeded
    /// document and assert the expected bundle layout:
    ///
    /// ```
    /// <root>/
    /// ├── spec.json
    /// └── Assets/
    ///     ├── Fonts/
    ///     └── Icons/
    /// ```
    ///
    /// Also writes the bundle to a temporary directory on disk and verifies it
    /// can be read back via `TokenforgeSpec.decode(from:)`. This exercises the
    /// full write→read path without needing the user to interact with Finder.
    ///
    nonisolated static func verifyBundleFileWrapperLayout() {
        let logger = Logger(subsystem: "io.apparata.Tokenforge", category: "BundleCheck")
        do {
            let seedSpec = try TokenforgeSpec.loadDefaultFromBundle()
            let wrapper = try makeBundleFileWrapper(from: seedSpec, existing: nil)

            // Structural assertions on the FileWrapper tree.
            guard wrapper.isDirectory, let root = wrapper.fileWrappers else {
                assertionFailure("Root FileWrapper is not a directory.")
                return
            }
            guard let specWrapper = root[BundleLayout.specFilename], specWrapper.isRegularFile else {
                assertionFailure("Missing or non-regular spec.json in bundle wrapper.")
                return
            }
            guard let assetsWrapper = root[BundleLayout.assetsDirectory], assetsWrapper.isDirectory,
                  let assetsChildren = assetsWrapper.fileWrappers else {
                assertionFailure("Missing or non-directory Assets/ in bundle wrapper.")
                return
            }
            guard let fonts = assetsChildren[BundleLayout.fontsDirectory], fonts.isDirectory else {
                assertionFailure("Missing or non-directory Assets/Fonts/ in bundle wrapper.")
                return
            }
            guard let icons = assetsChildren[BundleLayout.iconsDirectory], icons.isDirectory else {
                assertionFailure("Missing or non-directory Assets/Icons/ in bundle wrapper.")
                return
            }

            // Round-trip the spec.json contents back through the decoder.
            guard let specData = specWrapper.regularFileContents else {
                assertionFailure("spec.json wrapper has no contents.")
                return
            }
            let decoded = try TokenforgeSpec.decode(from: specData)
            guard decoded == seedSpec else {
                assertionFailure("Spec after FileWrapper round-trip does not equal the seed.")
                return
            }

            // Actually write the bundle to disk in a temp directory to catch any
            // issues in FileWrapper's serialization step that in-memory checks miss.
            let tempRoot = FileManager.default.temporaryDirectory
                .appendingPathComponent("tokenforge-bundle-check-\(UUID().uuidString)", isDirectory: true)
                .appendingPathExtension("tokenforge")
            try wrapper.write(to: tempRoot, options: [.atomic], originalContentsURL: nil)
            defer { try? FileManager.default.removeItem(at: tempRoot) }

            let specOnDisk = tempRoot.appendingPathComponent(BundleLayout.specFilename)
            let fontsOnDisk = tempRoot
                .appendingPathComponent(BundleLayout.assetsDirectory)
                .appendingPathComponent(BundleLayout.fontsDirectory)
            let iconsOnDisk = tempRoot
                .appendingPathComponent(BundleLayout.assetsDirectory)
                .appendingPathComponent(BundleLayout.iconsDirectory)

            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: specOnDisk.path, isDirectory: &isDir), !isDir.boolValue else {
                assertionFailure("spec.json missing from on-disk bundle.")
                return
            }
            guard FileManager.default.fileExists(atPath: fontsOnDisk.path, isDirectory: &isDir), isDir.boolValue else {
                assertionFailure("Assets/Fonts/ missing from on-disk bundle.")
                return
            }
            guard FileManager.default.fileExists(atPath: iconsOnDisk.path, isDirectory: &isDir), isDir.boolValue else {
                assertionFailure("Assets/Icons/ missing from on-disk bundle.")
                return
            }

            // Read the bundle back from disk via the same decode helper that
            // SwiftUI's init(configuration:) uses, to prove the read path
            // agrees with fileWrapper(snapshot:).
            let readbackWrapper = try FileWrapper(url: tempRoot, options: [.immediate])
            let readbackSpec = try decodeSpec(fromBundleWrapper: readbackWrapper)
            guard readbackSpec == seedSpec else {
                assertionFailure("Spec read back from on-disk bundle does not equal the seed.")
                return
            }

            logger.info("Bundle FileWrapper layout verified end-to-end (spec.json \(specData.count, privacy: .public) bytes, read-back ok).")
        } catch {
            assertionFailure("Bundle FileWrapper check failed: \(error)")
        }
    }
}

#endif
