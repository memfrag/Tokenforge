//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

enum PreviewSample: String, CaseIterable, Identifiable, Hashable {
    case paymentDetails
    case list
    case settings
    case emptyState

    var id: String { rawValue }

    var label: String {
        switch self {
        case .paymentDetails: return "Payment Details"
        case .list: return "List"
        case .settings: return "Settings"
        case .emptyState: return "Empty State"
        }
    }

    var subtitle: String {
        switch self {
        case .paymentDetails: return "Hero + card + action"
        case .list: return "listItem · navBar"
        case .settings: return "form rows · toggles"
        case .emptyState: return "illustration + CTA"
        }
    }
}

enum PreviewState: String, CaseIterable, Identifiable, Hashable {
    case `default`
    case pressed
    case disabled
    case selected

    var id: String { rawValue }

    var label: String {
        switch self {
        case .default: return "Default"
        case .pressed: return "Pressed"
        case .disabled: return "Disabled"
        case .selected: return "Selected"
        }
    }
}

struct PreviewPane: View {

    @Bindable var document: TokenforgeDocument

    @State private var selectedSample: PreviewSample = .paymentDetails
    @State private var appearance: TokenResolver.Appearance = .light
    @State private var state: PreviewState = .default
    @State private var showEmphasisOverlay: Bool = false

    private var resolvedTokens: ResolvedTokens {
        ResolvedTokens(spec: document.spec, appearance: appearance)
    }

    var body: some View {
        Pane {
            HStack(spacing: 0) {
                SampleList(selection: $selectedSample)
                    .frame(width: 220)
                    .background(Color(nsColor: .textBackgroundColor).opacity(0.55))
                Divider().ignoresSafeArea()
                stage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Preview")
    }

    private var stage: some View {
        VStack(spacing: 0) {
            PaneHeader(
                title: selectedSample.label,
                subtitle: "\(selectedSample.subtitle) — live render from spec tokens."
            ) {
                EmptyView()
            }

            PreviewControls(
                appearance: $appearance,
                state: $state,
                showEmphasisOverlay: $showEmphasisOverlay
            )
            .padding(.horizontal, 28)
            .padding(.top, 14)

            ScrollView {
                VStack {
                    iPhoneFrame(appearance: appearance) {
                        sampleContent
                    }
                    .environment(\.resolvedTokens, resolvedTokens)
                    .padding(.top, 18)
                    .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    @ViewBuilder
    private var sampleContent: some View {
        switch selectedSample {
        case .paymentDetails:
            PaymentDetailsSample(state: state, showEmphasis: showEmphasisOverlay)
        case .list:
            ListSample(state: state, showEmphasis: showEmphasisOverlay)
        case .settings:
            SettingsSample(state: state, showEmphasis: showEmphasisOverlay)
        case .emptyState:
            EmptyStateSample(state: state, showEmphasis: showEmphasisOverlay)
        }
    }
}

// MARK: - Sample list

private struct SampleList: View {

    @Binding var selection: PreviewSample

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("BUILT-IN SAMPLES")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 14)
                .padding(.top, 18)
                .padding(.bottom, 8)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(PreviewSample.allCases) { sample in
                        SampleListRow(
                            sample: sample,
                            isSelected: sample == selection
                        ) {
                            selection = sample
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

private struct SampleListRow: View {

    let sample: PreviewSample
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                Thumbnail(isSelected: isSelected)
                VStack(alignment: .leading, spacing: 2) {
                    Text(sample.label)
                        .font(.system(size: 12.5, weight: isSelected ? .medium : .regular))
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                    Text(sample.subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.75) : Color.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct Thumbnail: View {
    let isSelected: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(LinearGradient(
                colors: [Color(white: 0.95), Color(white: 0.84)],
                startPoint: .top,
                endPoint: .bottom
            ))
            .frame(width: 22, height: 34)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(isSelected ? Color.white : Color.primary.opacity(0.2), lineWidth: isSelected ? 1.5 : 0.5)
            )
            .overlay(
                Rectangle()
                    .fill(Color.primary.opacity(0.25))
                    .frame(height: 3)
                    .padding(.horizontal, 4)
                    .padding(.top, 12),
                alignment: .top
            )
    }
}

#Preview {
    PreviewPane(document: TokenforgeDocument())
        .frame(width: 1100, height: 760)
}
