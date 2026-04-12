//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// Per-document root view hosted inside the `DocumentGroup` scene in `MacApp`.
///
/// Owns the split view (sidebar + detail + inspector) and binds to a
/// `TokenforgeDocument` reference so every pane can observe and mutate the
/// same spec.
///
struct DocumentWindow: View {

    @Bindable var document: TokenforgeDocument

    var body: some View {
        Sidebar(document: document)
            .frame(minWidth: 960, minHeight: 620)
            .appEnvironment(.default)
            .focusedSceneValue(\.tokenforgeDocument, document)
    }
}
