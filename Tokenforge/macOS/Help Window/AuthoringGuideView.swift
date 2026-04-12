//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// Renders the bundled `AuthoringGuide.md` in a readable, macOS-native
/// document layout. Not a full CommonMark implementation — just enough to
/// read the authoring guide comfortably inside the Help window.
///
/// Supports:
/// - ATX headings (#, ##, ###, ####) with graduated type sizes
/// - Fenced code blocks (```)
/// - Bullet lists
/// - Inline formatting via `AttributedString(markdown:)` — bold, italic,
///   code spans, links
///
struct AuthoringGuideView: View {

    let markdown: String

    private var blocks: [MarkdownBlock] {
        MarkdownBlock.parse(markdown)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                    blockView(block)
                }
            }
            .padding(.horizontal, 42)
            .padding(.vertical, 32)
            .frame(maxWidth: 760, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color(nsColor: .textBackgroundColor))
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            Text(attributed(text))
                .font(headingFont(level))
                .fontWeight(headingWeight(level))
                .foregroundStyle(.primary)
                .padding(.top, level == 1 ? 6 : 10)
                .padding(.bottom, 2)
        case .paragraph(let text):
            Text(attributed(text))
                .font(.system(size: 14))
                .lineSpacing(3)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        case .codeBlock(let content):
            Text(content)
                .font(.system(size: 12.5, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color(nsColor: .textBackgroundColor).opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(.separator, lineWidth: 0.5)
                )
        case .list(let items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text(attributed(item))
                            .font(.system(size: 14))
                            .lineSpacing(2)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func attributed(_ raw: String) -> AttributedString {
        if let attributed = try? AttributedString(markdown: raw, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return attributed
        }
        return AttributedString(raw)
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: return .system(size: 26)
        case 2: return .system(size: 20)
        case 3: return .system(size: 16)
        default: return .system(size: 14)
        }
    }

    private func headingWeight(_ level: Int) -> Font.Weight {
        switch level {
        case 1: return .bold
        case 2: return .semibold
        case 3: return .semibold
        default: return .medium
        }
    }
}

// MARK: - Parser

enum MarkdownBlock: Equatable {
    case heading(level: Int, text: String)
    case paragraph(text: String)
    case codeBlock(text: String)
    case list(items: [String])

    /// Splits a markdown string into the block set above. Minimal state
    /// machine: blank lines close paragraphs and lists; fenced code spans
    /// toggle verbatim mode.
    static func parse(_ markdown: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var paragraphBuffer: [String] = []
        var listBuffer: [String] = []
        var codeBuffer: [String] = []
        var inCodeBlock = false

        func flushParagraph() {
            if !paragraphBuffer.isEmpty {
                blocks.append(.paragraph(text: paragraphBuffer.joined(separator: " ")))
                paragraphBuffer.removeAll()
            }
        }
        func flushList() {
            if !listBuffer.isEmpty {
                blocks.append(.list(items: listBuffer))
                listBuffer.removeAll()
            }
        }
        func flushCode() {
            blocks.append(.codeBlock(text: codeBuffer.joined(separator: "\n")))
            codeBuffer.removeAll()
        }

        let lines = markdown.components(separatedBy: "\n")
        for line in lines {
            if inCodeBlock {
                if line.hasPrefix("```") {
                    flushCode()
                    inCodeBlock = false
                } else {
                    codeBuffer.append(line)
                }
                continue
            }

            if line.hasPrefix("```") {
                flushParagraph()
                flushList()
                inCodeBlock = true
                continue
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                flushParagraph()
                flushList()
                continue
            }

            if let headingLevel = atxHeadingLevel(for: trimmed) {
                flushParagraph()
                flushList()
                let text = String(trimmed.drop(while: { $0 == "#" }))
                    .trimmingCharacters(in: .whitespaces)
                blocks.append(.heading(level: headingLevel, text: text))
                continue
            }

            if trimmed.hasPrefix("- ") {
                flushParagraph()
                listBuffer.append(String(trimmed.dropFirst(2)))
                continue
            }

            // Regular paragraph line.
            flushList()
            paragraphBuffer.append(trimmed)
        }

        flushParagraph()
        flushList()
        if inCodeBlock {
            // Unterminated fence — emit whatever was buffered.
            flushCode()
        }

        return blocks
    }

    private static func atxHeadingLevel(for line: String) -> Int? {
        var hashes = 0
        for char in line {
            if char == "#" {
                hashes += 1
                if hashes > 6 {
                    return nil
                }
            } else if char == " " {
                return hashes > 0 ? hashes : nil
            } else {
                return nil
            }
        }
        return nil
    }
}
