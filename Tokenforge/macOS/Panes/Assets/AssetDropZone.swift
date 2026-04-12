//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

/// Translucent drop overlay that highlights when the user drags a file
/// over the asset panes. Shared by `FontsPane` and `IconsPane`.
///
/// Applied via `.overlay` on the content so it only renders the outline +
/// "Drop to add" copy while the drag is active, staying out of the layout
/// otherwise.
///
struct AssetDropOverlay: View {

    let isTargeted: Bool
    let prompt: String

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(
                Color.accentColor,
                style: StrokeStyle(lineWidth: 2, dash: [6, 4])
            )
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.accentColor.opacity(0.08))
            )
            .overlay {
                VStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundStyle(Color.accentColor)
                    Text(prompt)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .opacity(isTargeted ? 1 : 0)
            .allowsHitTesting(false)
            .animation(.easeOut(duration: 0.12), value: isTargeted)
    }
}

/// Helper that consumes an `[NSItemProvider]` array from `.onDrop(of:)`
/// and returns a dictionary of `filename → Data` for files whose extension
/// is in the `allowedExtensions` set. The closure runs asynchronously
/// because `NSItemProvider.loadFileRepresentation` is asynchronous;
/// the completion handler is called on the main actor.
///
/// Returns `true` if at least one provider was kicked off, `false` if
/// nothing matched. The async completion may still produce an empty
/// dictionary if every provider failed.
///
@MainActor
enum AssetDropCoordinator {

    static func handleDrop(
        providers: [NSItemProvider],
        allowedExtensions: Set<String>,
        completion: @MainActor @escaping ([String: Data]) -> Void
    ) -> Bool {
        let candidates = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }
        guard !candidates.isEmpty else {
            return false
        }

        // Use a reference-type collector with an internal lock, so the
        // NSItemProvider callback closures (which run on random threads)
        // can write into a shared dictionary without Swift 6 concurrency
        // checking rejecting a captured `var`. Still uses DispatchGroup
        // for completion because `NSItemProvider` isn't `Sendable` and
        // can't be moved into `Task.detached` / `withTaskGroup`.
        let collector = AssetDropCollector()
        let group = DispatchGroup()

        for provider in candidates {
            group.enter()
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                defer { group.leave() }
                guard let url else {
                    return
                }
                let filename = url.lastPathComponent
                let ext = (filename as NSString).pathExtension.lowercased()
                guard allowedExtensions.contains(ext) else {
                    return
                }
                guard let bytes = try? Data(contentsOf: url) else {
                    return
                }
                collector.insert(filename: filename, data: bytes)
            }
        }

        group.notify(queue: .main) {
            let drained = collector.drain()
            Task { @MainActor in
                completion(drained)
            }
        }

        return true
    }
}

/// Lock-protected thread-safe container for drop loading. Declared
/// `nonisolated` so the `NSItemProvider.loadObject` callback closures
/// (which run on random threads) can call it directly, and
/// `@unchecked Sendable` because the `NSLock` manually serializes every
/// access to the internal dictionary.
nonisolated private final class AssetDropCollector: @unchecked Sendable {

    private let lock = NSLock()
    private var storage: [String: Data] = [:]

    func insert(filename: String, data: Data) {
        lock.lock()
        defer { lock.unlock() }
        storage[filename] = data
    }

    func drain() -> [String: Data] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }
}

/// Returns `newFilename` if it doesn't collide with any key in `existing`.
/// Otherwise appends ` (N)` before the extension and tries again until
/// a unique name is found.
nonisolated func uniqueFilename(_ preferred: String, amongst existing: Set<String>) -> String {
    if !existing.contains(preferred) {
        return preferred
    }
    let base = (preferred as NSString).deletingPathExtension
    let ext = (preferred as NSString).pathExtension
    var counter = 2
    while true {
        let candidate = ext.isEmpty
            ? "\(base) (\(counter))"
            : "\(base) (\(counter)).\(ext)"
        if !existing.contains(candidate) {
            return candidate
        }
        counter += 1
    }
}
