import SwiftUI

struct AddWidgetSheet: View {
    @Binding var isPresented: Bool
    let actionRegistry: ActionRegistry
    var onSave: (WidgetConfig) -> Void

    @State private var selectedType: WidgetType = .gauge
    @State private var selectedSource: WidgetDataSource = .health
    @State private var title = ""
    @State private var selectedActions: Set<String> = []
    @State private var actionSearch = ""

    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

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
                        let attachedActions = selectedActions.compactMap { actionId -> WidgetActionConfig? in
                            guard let action = actionRegistry.actions.first(where: { $0.id == actionId }) else { return nil }
                            let tierType: ActionTierType = switch action.tier {
                                case .runbook: .runbook
                                case .ai: .ai
                                case .hybrid: .hybrid
                            }
                            return WidgetActionConfig(name: action.name, tier: tierType)
                        }
                        let config = WidgetConfig(
                            type: selectedType,
                            dataSource: selectedSource,
                            title: title.isEmpty ? selectedSource.displayName : title,
                            sortOrder: 0,
                            actions: attachedActions
                        )
                        onSave(config)
                        isPresented = false
                    } label: {
                        Text("Add to Dashboard")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Add Widget")
            .navigationBarTitleDisplayMode(.inline)
            .task { await actionRegistry.loadAll() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    private func isSelected(_ action: HermesAction) -> Bool {
        selectedActions.contains(action.id)
    }

    private var filteredActions: [HermesAction] {
        let allForSource = actionRegistry.actions(for: selectedSource)
        guard !actionSearch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return tierOrdered(allForSource)
        }
        let query = actionSearch.lowercased()
        let matches = allForSource.filter { action in
            action.name.lowercased().contains(query) ||
            (action.description?.lowercased().contains(query) ?? false)
        }
        return tierOrdered(matches)
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

struct SelectableGridCard: View {
    let icon: String
    let label: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
            Text(label)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

struct TierBadge: View {
    let tier: ActionTierType

    var body: some View {
        Text(tier.rawValue)
            .font(.caption2.bold())
            .foregroundStyle(tierColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(tierColor.opacity(0.15)))
    }

    private var tierColor: Color {
        switch tier {
        case .runbook: .blue
        case .ai: .purple
        case .hybrid: .orange
        }
    }
}