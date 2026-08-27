import SwiftUI

struct WidgetActionBar: View {
    let dataSource: WidgetDataSource
    var pinnedActions: [WidgetActionConfig] = []
    let actionRegistry: ActionRegistry
    @Bindable var executor: ActionExecutor

    var body: some View {
        let resolved = resolvedActions

        if !resolved.isEmpty {
            HStack(spacing: 8) {
                ForEach(resolved) { item in
                    Button {
                        Task { await executor.execute(item.action) }
                    } label: {
                        HStack(spacing: 4) {
                            if item.isPinned {
                                Image(systemName: "pin.fill")
                                    .font(.caption2)
                            }
                            tierIcon(item.action.tier)
                            Text(item.action.name)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(tierColor(item.action.tier).opacity(0.12))
                        )
                        .foregroundStyle(tierColor(item.action.tier))
                    }
                    .buttonStyle(.plain)
                    .disabled(isRunning(item.action))
                }
            }
            .padding(.top, 8)
        }
    }

    private var resolvedActions: [ResolvedAction] {
        let allForSource = actionRegistry.actions(for: dataSource)
        var result: [ResolvedAction] = []

        // First: pinned actions (user-selected)
        for pinned in pinnedActions {
            if let match = allForSource.first(where: { $0.name == pinned.name }) {
                result.append(ResolvedAction(action: match, isPinned: true))
            }
            if result.count >= 3 { break }
        }

        // Then: auto-fill from registry recommendations
        let pinnedNames = Set(result.map { $0.action.name })
        for action in allForSource where !pinnedNames.contains(action.name) {
            result.append(ResolvedAction(action: action, isPinned: false))
            if result.count >= 3 { break }
        }

        return result
    }

    private func isRunning(_ action: HermesAction) -> Bool {
        if case .running(let id) = executor.state, id == action.id {
            return true
        }
        return false
    }

    private func tierIcon(_ tier: ActionTier) -> some View {
        Image(systemName: tierIconName(tier))
            .font(.caption2)
    }

    private func tierIconName(_ tier: ActionTier) -> String {
        switch tier {
        case .runbook: "terminal"
        case .ai: "sparkles"
        case .hybrid: "arrow.triangle.branch"
        }
    }

    private func tierColor(_ tier: ActionTier) -> Color {
        switch tier {
        case .runbook: .green
        case .ai: .purple
        case .hybrid: .orange
        }
    }
}

private struct ResolvedAction: Identifiable {
    let action: HermesAction
    let isPinned: Bool

    var id: String { action.id }
}