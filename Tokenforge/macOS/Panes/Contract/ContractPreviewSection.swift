//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// Live read-only preview of the markdown the LLM contract exporter
/// produces. Updates as the author edits any field that the contract reads
/// from — primitives, semantic tokens, hierarchy rules, accessibility,
/// document meta, and contract overrides — because every dependency reads
/// from `document.spec` which is `@Observable`.
///
/// The contract is rendered via the same `AuthoringGuideView` markdown
/// renderer the Help window uses, so headings, code blocks, bullet lists,
/// and inline formatting all render correctly.
///
/// Internal scroll height is capped so the preview doesn't push the
/// editors above off-screen on small windows; the preview itself scrolls.
///
struct ContractPreviewSection: View {

    let document: TokenforgeDocument

    private var markdown: String {
        let data = LLMContractExporter.export(document.spec)
        return String(data: data, encoding: .utf8) ?? ""
    }

    var body: some View {
        SectionCard(title: "Preview", aside: "live render of llm-design-contract.md") {
            EmptyView()
        } content: {
            AuthoringGuideView(markdown: markdown)
                .frame(maxWidth: .infinity)
                .frame(height: 480)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(.separator, lineWidth: 0.5)
                )
        }
    }
}
