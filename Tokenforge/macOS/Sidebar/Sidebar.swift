//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import SwiftUIToolbox

struct Sidebar: View {

    @Bindable var document: TokenforgeDocument

    @State private var selection: SidebarPane? = .primitives

    @State private var isInspectorPresented: Bool = true

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {

                Section(header: Text("Document")) {

                    NavigationLink(value: SidebarPane.primitives) {
                        countedLabel("Primitives", systemImage: "square.stack.3d.up", count: primitivesCount)
                    }

                    NavigationLink(value: SidebarPane.semantic) {
                        countedLabel("Semantic", systemImage: "link", count: semanticCount)
                    }

                    NavigationLink(value: SidebarPane.hierarchy) {
                        countedLabel("Hierarchy", systemImage: "list.bullet.indent", count: hierarchyCount)
                    }

                    NavigationLink(value: SidebarPane.components) {
                        countedLabel("Components", systemImage: "square.on.square", count: componentsCount)
                    }

                    NavigationLink(value: SidebarPane.preview) {
                        Label("Preview", systemImage: "iphone.gen3")
                    }

                    NavigationLink(value: SidebarPane.contract) {
                        Label("Contract & Export", systemImage: "doc.text.below.ecg")
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200, idealWidth: 224, maxWidth: 320)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                SidebarFooter(meta: document.spec.meta, schemaVersion: document.spec.schemaVersion)
            }
        } detail: {
            switch selection {
            case .primitives:
                PrimitivesPane(document: document)
            case .semantic:
                SemanticPane(document: document)
            case .hierarchy:
                HierarchyPane(document: document)
            case .components:
                ComponentsPane(document: document)
            case .preview:
                PreviewPane(document: document)
            case .contract:
                ContractPane(document: document)
            case .none:
                EmptyPane()
            }
        }
        .inspector(isPresented: $isInspectorPresented) {
            InspectorPanel(document: document, activePane: selection ?? .primitives)
                .inspectorColumnWidth(min: 240, ideal: 280, max: 360)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ProblemsChip(
                    summary: ProblemSummary(problems: Validator.validate(document.spec))
                ) {
                    isInspectorPresented = true
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isInspectorPresented.toggle()
                } label: {
                    Label("Toggle Inspector", systemImage: "sidebar.trailing")
                }
            }
        }
    }

    // MARK: - Counted sidebar row

    /// A sidebar label that renders the usual SF Symbol + title plus a
    /// trailing monospaced-digit count badge, matching the design
    /// exploration. Count colors use `.tertiary` so the built-in sidebar
    /// selection state inverts them correctly on the accent fill.
    private func countedLabel(_ title: String, systemImage: String, count: Int) -> some View {
        Label {
            HStack {
                Text(title)
                Spacer(minLength: 6)
                Text("\(count)")
                    .font(.system(size: 11))
                    .monospacedDigit()
                    .foregroundStyle(.tertiary)
            }
        } icon: {
            Image(systemName: systemImage)
        }
    }

    // MARK: - Pane counts

    private var primitivesCount: Int {
        let p = document.spec.primitives
        return p.color.count
            + p.spacing.count
            + p.radius.count
            + p.typography.fontFamilies.count
            + p.typography.fontSizes.count
            + p.typography.fontWeights.count
            + p.typography.lineHeights.count
            + p.elevation.count
            + p.stroke.count
            + p.motion.durations.count
            + p.motion.curves.count
    }

    private var semanticCount: Int {
        let s = document.spec.semantic
        return s.color.count + s.type.count + s.spacing.count + s.radius.count
    }

    private var hierarchyCount: Int {
        document.spec.hierarchy.rules.count
    }

    /// Components is a fixed set of twelve bespoke contracts.
    private var componentsCount: Int { 12 }
}
