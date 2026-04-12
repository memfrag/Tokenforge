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
                        Label("Primitives", systemImage: "square.stack.3d.up")
                    }

                    NavigationLink(value: SidebarPane.semantic) {
                        Label("Semantic", systemImage: "link")
                    }

                    NavigationLink(value: SidebarPane.hierarchy) {
                        Label("Hierarchy", systemImage: "list.bullet.indent")
                    }

                    NavigationLink(value: SidebarPane.components) {
                        Label("Components", systemImage: "square.on.square")
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
}
