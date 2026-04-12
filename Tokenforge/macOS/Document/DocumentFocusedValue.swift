//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// Focused scene value that exposes the active `TokenforgeDocument` to
/// `Commands` defined on the `DocumentGroup`. `DocumentWindow` installs the
/// value via `.focusedSceneValue(\.tokenforgeDocument, document)` and the
/// export commands read it via `@FocusedValue`.
///
private struct TokenforgeDocumentFocusedValueKey: FocusedValueKey {
    typealias Value = TokenforgeDocument
}

extension FocusedValues {
    var tokenforgeDocument: TokenforgeDocument? {
        get { self[TokenforgeDocumentFocusedValueKey.self] }
        set { self[TokenforgeDocumentFocusedValueKey.self] = newValue }
    }
}
