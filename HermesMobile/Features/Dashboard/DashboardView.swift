import SwiftUI

struct DashboardView: View {
    let server: URL
    @Bindable var authManager: AuthManager
    @State private var viewModel: DashboardViewModel
    @State private var capabilityProbe: ServerCapabilityProbe
    @State private var actionRegistry: ActionRegistry
    @State private var actionExecutor: ActionExecutor
    @State private var widgetStore = WidgetStore()
    @State private var showingAddWidget = false
    @State private var editingWidget: WidgetConfig?
    @State private var isEditing = false
    @State private var widgetToDelete: WidgetConfig?

    init(server: URL, authManager: AuthManager) {
        self.server = server
        self.authManager = authManager
        let client = APIClient(baseURL: server)
        let provider = APIClientDashboardAdapter(client: client)
        let probe = ServerCapabilityProbe(baseURL: server)
        _capabilityProbe = State(initialValue: probe)
        _viewModel = State(
            initialValue: DashboardViewModel(provider: provider, capabilityProbe: probe)
        )
        _actionRegistry = State(
            initialValue: ActionRegistry(provider: provider)
        )
        _actionExecutor = State(
            initialValue: ActionExecutor(provider: provider)
        )
        WidgetRendererRegistry.registerAll()
    }

    var body: some View {
        NavigationStack {
            Group {
                if isEditing {
                    List {
                        ForEach(visibleWidgets) { config in
                            widgetRow(for: config)
                        }
                        .onMove { source, destination in
                            widgetStore.moveWidget(from: source, to: destination)
                        }
                    }
                    .environment(\.editMode, .constant(isEditing ? .active : .inactive))
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            if viewModel.isLoading && viewModel.health == nil {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 48)
                            }

                            ForEach(visibleWidgets) { config in
                                widgetRow(for: config)
                            }
                        }
                        .padding()
                    }
                    .refreshable { await viewModel.loadAll() }
                }
            }
            .navigationTitle("Hermes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        Button("Done") { isEditing = false }
                    } else {
                        Menu {
                            Button {
                                showingAddWidget = true
                            } label: {
                                Label("Add Widget", systemImage: "plus.square")
                            }
                            Button {
                                isEditing = true
                            } label: {
                                Label("Reorder Widgets", systemImage: "arrow.up.arrow.down")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddWidget) {
                AddWidgetSheet(isPresented: $showingAddWidget, actionRegistry: actionRegistry) { config in
                    widgetStore.addWidget(config)
                }
            }
            .task {
                await capabilityProbe.probe()
                await viewModel.loadAll()
                await actionRegistry.loadAll()
            }
            .task { widgetStore.loadWidgets() }
            .overlay(alignment: .bottom) {
                if case .success(_, let message) = actionExecutor.state {
                    Text(message)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(.green))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 20)
                        .onAppear {
                            Task {
                                try? await Task.sleep(for: .seconds(2))
                                actionExecutor.clearState()
                            }
                        }
                }
                if case .error(_, let message) = actionExecutor.state {
                    Text(message)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(.red))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 20)
                        .onAppear {
                            Task {
                                try? await Task.sleep(for: .seconds(3))
                                actionExecutor.clearState()
                            }
                        }
                }
            }
        }
        .sheet(item: $editingWidget) { widgetConfig in
            EditWidgetSheet(config: widgetConfig, actionRegistry: actionRegistry) { updatedConfig in
                widgetStore.updateWidget(updatedConfig)
                editingWidget = nil
            }
        }
        .alert("Remove Widget?", isPresented: Binding(
            get: { widgetToDelete != nil },
            set: { if !$0 { widgetToDelete = nil } }
        )) {
            Button("Remove", role: .destructive) {
                if let widgetToDelete {
                    widgetStore.removeWidget(id: widgetToDelete.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var visibleWidgets: [WidgetConfig] {
        widgetStore.widgets.filter(\.isEnabled).sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    private func widgetView(for config: WidgetConfig) -> some View {
        let context = WidgetRenderContext(
            health: viewModel.health,
            insights: viewModel.insights,
            recentCrons: viewModel.recentCrons,
            pendingApprovals: viewModel.pendingApprovals,
            respondToApproval: { approval, choice in
                await viewModel.respondToApproval(approval, choice: choice)
            }
        )
        return WidgetRendererRegistry.shared.view(for: config, context: context)
    }

    private func widgetRow(for config: WidgetConfig) -> some View {
        VStack(spacing: 0) {
            widgetView(for: config)
            WidgetActionBar(
                dataSource: config.dataSource,
                pinnedActions: config.actions,
                actionRegistry: actionRegistry,
                executor: actionExecutor
            )
        }
        .contextMenu {
            Button {
                editingWidget = config
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                widgetToDelete = config
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }
}
