//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// Identifier for each of the twelve built-in component editors. Also drives
/// the left-hand component list.
enum ComponentSelection: String, CaseIterable, Identifiable, Hashable {
    case button
    case card
    case textField
    case listItem
    case navBar
    case tabBar
    case toolbar
    case segmentedControl
    case toggle
    case alert
    case toastBanner
    case badgeTag

    var id: String { rawValue }

    var label: String {
        switch self {
        case .button: return "button"
        case .card: return "card"
        case .textField: return "textField"
        case .listItem: return "listItem"
        case .navBar: return "navBar"
        case .tabBar: return "tabBar"
        case .toolbar: return "toolbar"
        case .segmentedControl: return "segmentedControl"
        case .toggle: return "toggle"
        case .alert: return "alert"
        case .toastBanner: return "toastBanner"
        case .badgeTag: return "badgeTag"
        }
    }

    var systemImage: String {
        switch self {
        case .button: return "cursorarrow.click.2"
        case .card: return "rectangle.on.rectangle"
        case .textField: return "character.cursor.ibeam"
        case .listItem: return "list.bullet"
        case .navBar: return "rectangle.portrait.topthird.inset.filled"
        case .tabBar: return "rectangle.bottomthird.inset.filled"
        case .toolbar: return "wrench.and.screwdriver"
        case .segmentedControl: return "rectangle.split.2x1"
        case .toggle: return "switch.2"
        case .alert: return "exclamationmark.bubble"
        case .toastBanner: return "bell"
        case .badgeTag: return "tag"
        }
    }

    var subtitle: String {
        switch self {
        case .button: return "Primary interactive element"
        case .card: return "Container with slot rules"
        case .textField: return "Labeled input"
        case .listItem: return "Row for lists"
        case .navBar: return "Top navigation bar"
        case .tabBar: return "Bottom tab bar"
        case .toolbar: return "Inline / bottom toolbar"
        case .segmentedControl: return "Segmented picker"
        case .toggle: return "Binary switch"
        case .alert: return "Modal confirmation"
        case .toastBanner: return "Transient feedback"
        case .badgeTag: return "Status labels"
        }
    }
}

struct ComponentsPane: View {

    @Bindable var document: TokenforgeDocument

    @Environment(\.undoManager) private var undoManager

    @State private var selection: ComponentSelection = .button

    var body: some View {
        Pane {
            HStack(spacing: 0) {
                ComponentListView(selection: $selection)
                    .frame(width: 220)
                    .background(Color(nsColor: .textBackgroundColor).opacity(0.55))
                Divider().ignoresSafeArea()
                detailContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Components")
    }

    @ViewBuilder
    private var detailContent: some View {
        VStack(spacing: 0) {
            PaneHeader(
                title: selection.label,
                subtitle: selection.subtitle
            ) {
                EmptyView()
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    editor(for: selection)
                    Spacer(minLength: 24)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    @ViewBuilder
    private func editor(for selection: ComponentSelection) -> some View {
        switch selection {
        case .button:
            ButtonComponentEditor(document: document, undoManager: undoManager)
        case .card:
            CardComponentEditor(document: document, undoManager: undoManager)
        case .textField:
            TextFieldComponentEditor(document: document, undoManager: undoManager)
        case .listItem:
            ListItemComponentEditor(document: document, undoManager: undoManager)
        case .navBar:
            NavBarComponentEditor(document: document, undoManager: undoManager)
        case .tabBar:
            TabBarComponentEditor(document: document, undoManager: undoManager)
        case .toolbar:
            ToolbarComponentEditor(document: document, undoManager: undoManager)
        case .segmentedControl:
            SegmentedControlComponentEditor(document: document, undoManager: undoManager)
        case .toggle:
            ToggleComponentEditor(document: document, undoManager: undoManager)
        case .alert:
            AlertComponentEditor(document: document, undoManager: undoManager)
        case .toastBanner:
            ToastBannerComponentEditor(document: document, undoManager: undoManager)
        case .badgeTag:
            BadgeTagComponentEditor(document: document, undoManager: undoManager)
        }
    }
}

// MARK: - Left list

private struct ComponentListView: View {

    @Binding var selection: ComponentSelection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("COMPONENTS")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 14)
                .padding(.top, 18)
                .padding(.bottom, 8)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(ComponentSelection.allCases) { component in
                        ComponentListRow(
                            component: component,
                            isSelected: component == selection
                        ) {
                            selection = component
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

private struct ComponentListRow: View {

    let component: ComponentSelection
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 9) {
                Image(systemName: component.systemImage)
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? Color.white : Color.secondary)
                    .frame(width: 16)
                Text(component.label)
                    .font(.system(size: 12.5))
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ComponentsPane(document: TokenforgeDocument())
        .frame(width: 1100, height: 720)
}
