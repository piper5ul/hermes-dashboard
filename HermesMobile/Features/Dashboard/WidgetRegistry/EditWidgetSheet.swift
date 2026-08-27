import SwiftUI

struct EditWidgetSheet: View {
    let config: WidgetConfig
    let actionRegistry: ActionRegistry
    var onSave: (WidgetConfig) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: WidgetType
    @State private var selectedSource: WidgetDataSource
    @State private var title: String
    @State private var selectedActions: Set<String> = []
    @State private var actionSearch = ""

    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    init(config: WidgetConfig, actionRegistry: ActionRegistry, onSave: @escaping (WidgetConfig) -> Void) {
        self.config = config
        self.actionRegistry = actionRegistry
        self.onSave = onSave
        _selectedType = State(initialValue: config.type)
        _selectedSource = State(initialValue: config.dataSource)
        _title = State(initialValue: config.title)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Widget Type") {
                    LazyVGrid(columns: gridColumns, spacing: 10) {
                        ForEach(WidgetType.allCases, id: \.self) { type in
                            SelectableGridCard(icon: type.icon, label: type.displayName, isSelected: selectedType == type)
                                .onTapGesture { selectedType = type }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }

                Section("Data Source") {
                    LazyVGrid(columns: gridColumns, spacing: 10) {
                        ForEach(WidgetDataSource.allCases, id: \.self) { source in
                            SelectableGridCard(icon: source.icon, label: source.displayName, isSelected: selectedSource == source)
                                .onTapGesture { selectedSource = source }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }

                Section("Title") {
                    TextField("\(selectedSource.displayName) widget", text: $title)
                }

                Section(actionSectionHeader) {
                    TextField("Search actions...", text: $actionSearch)
                        .textFieldStyle(.roundedBorder)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

                    let filtered = filteredActions
                    if actionRegistry.isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Fetching actions…")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else if filtered.isEmpty {
                        Text(actionSearch.isEmpty ? "No actions available" : "No matching actions")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filtered) { action in
                            Button {
                                toggleAction(action)
                            } label: {
                                HStack(spacing: 12) {
                                    TierBadge(tier: tierType(for: action))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(action.name)
                                        if let desc = action.description, !desc.isEmpty {
                                            Text(desc)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: isSelected(action) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(isSelected(action) ? Color.blue : Color(.systemGray3))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Section {
                    Button {
                        let updatedConfig = WidgetConfig(
                            id: config.id,
                            type: selectedType,
                            dataSource: selectedSource,
                            title: title.isEmpty ? selectedSource.displayName : title,
                            sortOrder: config.sortOrder,
                            actions: attachedActions,
                            isEnabled: config.isEnabled
                        )
                        onSave(updatedConfig)
                        dismiss()
                    } label: {
                        Text("Save Changes")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Edit Widget")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await actionRegistry.loadAll()
                populateSelectedActions()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var attachedActions: [WidgetActionConfig] {
        selectedActions.compactMap { actionId -> WidgetActionConfig? in
            guard let action = actionRegistry.actions.first(where: { $0.id == actionId }) else { return nil }
            let tierType: ActionTierType = switch action.tier {
                case .runbook: .runbook
                case .ai: .ai
                case .hybrid: .hybrid
            }
            return WidgetActionConfig(name: action.name, tier: tierType)
        }
    }

    private func populateSelectedActions() {
        let configNames = Set(config.actions.map(\.name))
        let ids = actionRegistry.actions
            .filter { configNames.contains($0.name) }
            .map(\.id)
        selectedActions = Set(ids)
    }

    private func isSelected(_ action: HermesAction) -> Bool {
        selectedActions.contains(action.id)
    }

    private var filteredActions: [HermesAction] {
        let allForSource = actionRegistry.actions(for: selectedSource)
        let candidates: [HermesAction]
        if actionSearch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            candidates = allForSource
        } else {
            let query = actionSearch.lowercased()
            candidates = allForSource.filter { action in
                action.name.lowercased().contains(query) ||
                (action.description?.lowercased().contains(query) ?? false)
            }
        }
        let ordered = tierOrdered(candidates)
        return ordered.filter { selectedActions.contains($0.id) } + ordered.filter { !selectedActions.contains($0.id) }
    }

    private var actionSectionHeader: String {
        let count = actionRegistry.actions(for: selectedSource).count
        if actionRegistry.isLoading { return "Loading Actions..." }
        if count == 0 { return "Attach Actions" }
        return "Attach Actions (\(count))"
    }

    private func tierOrdered(_ actions: [HermesAction]) -> [HermesAction] {
        let rank: (ActionTierType) -> Int = { tier in
            switch tier {
            case .ai: 0
            case .runbook: 1
            case .hybrid: 2
            }
        }
        return actions.sorted { rank(tierType(for: $0)) < rank(tierType(for: $1)) }
    }

    private func toggleAction(_ action: HermesAction) {
        if selectedActions.contains(action.id) {
            selectedActions.remove(action.id)
        } else {
            selectedActions.insert(action.id)
        }
    }

    private func tierType(for action: HermesAction) -> ActionTierType {
        switch action.tier {
        case .runbook: .runbook
        case .ai: .ai
        case .hybrid: .hybrid
        }
    }
}