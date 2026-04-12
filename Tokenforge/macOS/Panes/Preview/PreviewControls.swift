//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// Row of controls above the iPhone frame: appearance picker, state picker,
/// and emphasis overlay toggle. Each drives an `@Binding` owned by the
/// preview pane so the rendered sample updates live.
///
struct PreviewControls: View {

    @Binding var appearance: TokenResolver.Appearance
    @Binding var state: PreviewState
    @Binding var showEmphasisOverlay: Bool

    var body: some View {
        HStack(spacing: 14) {
            appearanceGroup
            stateGroup
            emphasisGroup
            Spacer(minLength: 0)
        }
    }

    private var appearanceGroup: some View {
        HStack(spacing: 6) {
            Text("Appearance")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            Picker("", selection: $appearance) {
                Label("Light", systemImage: "sun.max").tag(TokenResolver.Appearance.light)
                Label("Dark", systemImage: "moon").tag(TokenResolver.Appearance.dark)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
        }
    }

    private var stateGroup: some View {
        HStack(spacing: 6) {
            Text("State")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            Picker("", selection: $state) {
                ForEach(PreviewState.allCases) { state in
                    Text(state.label).tag(state)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .fixedSize()
        }
    }

    private var emphasisGroup: some View {
        Toggle(isOn: $showEmphasisOverlay) {
            Text("Emphasis overlay")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .toggleStyle(.switch)
        .controlSize(.small)
    }
}
