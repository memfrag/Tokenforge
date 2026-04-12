//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import CoreGraphics
import CoreText
import os

/// Process-wide registry of custom fonts loaded from `.tokenforge`
/// documents. A document can be opened multiple times in the lifetime of
/// one app process; each reopen should not double-register the same fonts.
///
/// Core Text registration is idempotent at the font level — registering the
/// same `CGFont` twice is harmless — but generating `CGFont` values from
/// raw `Data` is not free, so the registry keeps a cheap content-hash set
/// to dedupe incoming blobs before touching Core Text.
///
/// The registry is `@MainActor`-isolated because every modification should
/// happen on the main actor (document reads hop to main via the
/// `ReferenceFileDocument` plumbing before the refresh is scheduled).
///
@MainActor
enum FontRegistry {

    private static var registeredHashes: Set<Int> = []
    private static var registeredPostScriptNames: Set<String> = []
    private static var filenameToPostScriptNames: [String: [String]] = [:]
    private static let logger = Logger(subsystem: "io.apparata.Tokenforge", category: "FontRegistry")

    /// The set of PostScript names currently known to the process. Grows
    /// as documents are opened; never shrinks for the lifetime of the app.
    static var postScriptNames: Set<String> {
        registeredPostScriptNames
    }

    /// Returns the PostScript names registered from `filename` so far.
    /// Used by the Fonts pane to resolve `Font.custom(name:size:)` for a
    /// live preview without re-parsing the font data on every render.
    static func postScriptNames(forFilename filename: String) -> [String] {
        filenameToPostScriptNames[filename] ?? []
    }

    /// Registers every font blob in `fontsByFilename`. Duplicates (by
    /// hash) are skipped. Returns the list of newly-registered PostScript
    /// names so callers can log or surface them.
    ///
    /// Uses the modern Core Text descriptor-based API
    /// (`CTFontManagerCreateFontDescriptorsFromData` +
    /// `CTFontManagerRegisterFontDescriptors`) rather than the deprecated
    /// `CTFontManagerRegisterGraphicsFont`.
    @discardableResult
    static func register(_ fontsByFilename: [String: Data]) -> [String] {
        var newlyRegistered: [String] = []
        for (filename, data) in fontsByFilename {
            let hash = stableHash(for: data)
            if registeredHashes.contains(hash) {
                continue
            }
            guard let descriptors = descriptors(from: data) else {
                logger.warning("Skipping \(filename, privacy: .public): could not extract descriptors.")
                continue
            }
            // The fourth parameter is a progress/error handler callback.
            // We don't need progress updates for Phase 10, so pass `nil`
            // and treat Core Text's lack of a reported failure as success.
            // The operation is idempotent, and the content-hash dedupe
            // above ensures we won't retry the same blob anyway.
            CTFontManagerRegisterFontDescriptors(
                descriptors as CFArray,
                .process,
                false,
                nil
            )
            registeredHashes.insert(hash)
            let psNames = descriptors.compactMap { descriptor -> String? in
                CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String
            }
            for psName in psNames {
                registeredPostScriptNames.insert(psName)
            }
            filenameToPostScriptNames[filename, default: []].append(contentsOf: psNames)
            newlyRegistered.append(contentsOf: psNames)
            logger.info("Registered \(psNames.count, privacy: .public) descriptor(s) from \(filename, privacy: .public).")
        }
        return newlyRegistered
    }

    // MARK: - Helpers

    private static func descriptors(from data: Data) -> [CTFontDescriptor]? {
        guard let descriptors = CTFontManagerCreateFontDescriptorsFromData(data as CFData) as? [CTFontDescriptor] else {
            return nil
        }
        return descriptors.isEmpty ? nil : descriptors
    }

    /// Cheap hash over the font bytes. Not cryptographic — we just want
    /// O(1) "have we seen this blob before" lookups.
    private static func stableHash(for data: Data) -> Int {
        var hasher = Hasher()
        hasher.combine(data.count)
        data.withUnsafeBytes { raw in
            if let base = raw.baseAddress, data.count >= 32 {
                // Sample the first 16 and last 16 bytes — plenty to distinguish
                // different font files in practice without hashing megabytes.
                let prefix = Data(bytes: base, count: 16)
                let suffix = Data(bytes: base.advanced(by: data.count - 16), count: 16)
                hasher.combine(prefix)
                hasher.combine(suffix)
            } else if let base = raw.baseAddress {
                hasher.combine(Data(bytes: base, count: data.count))
            }
        }
        return hasher.finalize()
    }
}
