import Foundation

@MainActor
@Observable
final class ActionRegistry {
    private let provider: any DashboardDataProvider
    private(set) var actions: [HermesAction] = []
    private(set) var isLoading = false
    private(set) var lastError: String?

    init(provider: any DashboardDataProvider) {
        self.provider = provider
    }

    func loadAll() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        async let skillsResult = provider.fetchSkills()
        async let cronsResult = provider.fetchCrons()

        var allActions: [HermesAction] = []

        // Skills → AI-tier actions
        if let skills = try? await skillsResult {
            let enabled = (skills.skills ?? []).filter { $0.disabled != true }
            allActions += enabled.compactMap { HermesAction.from(skill: $0) }
        }

        // Crons → Runbook-tier actions
        if let crons = try? await cronsResult {
            let enabled = (crons.jobs ?? []).filter { $0.enabled != false }
            allActions += enabled.compactMap { HermesAction.from(cron: $0) }
        }

        actions = allActions
    }

    /// Returns actions relevant to a specific widget data source
    func actions(for dataSource: WidgetDataSource) -> [HermesAction] {
        actions.filter { $0.contexts.contains(dataSource.rawValue) }
    }
}