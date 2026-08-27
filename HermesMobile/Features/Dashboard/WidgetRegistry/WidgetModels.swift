import Foundation
import SwiftUI

enum WidgetType: String, Codable, CaseIterable {
    case gauge
    case sparkline
    case areaChart
    case barChart
    case statCard
    case multiStat
    case list
    case heatmap
    case timeline

    var displayName: String {
        switch self {
        case .gauge: "Gauge"
        case .sparkline: "Sparkline"
        case .areaChart: "Area Chart"
        case .barChart: "Bar Chart"
        case .statCard: "Stat Card"
        case .multiStat: "Multi-Stat"
        case .list: "List"
        case .heatmap: "Heatmap"
        case .timeline: "Timeline"
        }
    }

    var icon: String {
        switch self {
        case .gauge: "gauge"
        case .sparkline: "chart.xyaxis.line"
        case .areaChart: "chart.line.uptrend.xyaxis"
        case .barChart: "chart.bar.fill"
        case .statCard: "number.square.fill"
        case .multiStat: "square.grid.3x3.fill"
        case .list: "list.bullet"
        case .heatmap: "chart.dots.scatter"
        case .timeline: "clock.arrow.circlepath"
        }
    }
}

enum WidgetDataSource: String, Codable, CaseIterable {
    case health
    case insights
    case crons
    case kanban
    case sessions
    case alerts

    var displayName: String {
        switch self {
        case .health: "System Health"
        case .insights: "Insights"
        case .crons: "Cron Jobs"
        case .kanban: "Kanban"
        case .sessions: "Sessions"
        case .alerts: "Alerts"
        }
    }

    var icon: String {
        switch self {
        case .health: "heart.fill"
        case .insights: "lightbulb.fill"
        case .crons: "clock.arrow.circlepath"
        case .kanban: "rectangle.3.group"
        case .sessions: "bubble.left.and.bubble.right.fill"
        case .alerts: "bell.badge.fill"
        }
    }
}

enum ActionTierType: String, Codable {
    case runbook
    case ai
    case hybrid
}

struct WidgetActionConfig: Codable, Identifiable {
    var id = UUID()
    var name: String
    var tier: ActionTierType
    var command: String?
}

struct WidgetConfig: Codable, Identifiable {
    var id = UUID()
    var type: WidgetType
    var dataSource: WidgetDataSource
    var title: String
    var sortOrder: Int
    var actions: [WidgetActionConfig]
    var isEnabled: Bool

    init(id: UUID = UUID(), type: WidgetType, dataSource: WidgetDataSource, title: String, sortOrder: Int, actions: [WidgetActionConfig] = [], isEnabled: Bool = true) {
        self.id = id
        self.type = type
        self.dataSource = dataSource
        self.title = title
        self.sortOrder = sortOrder
        self.actions = actions
        self.isEnabled = isEnabled
    }
}

@MainActor
@Observable
final class WidgetStore {
    private static let defaultsKey = "dashboard_widgets"

    private(set) var widgets: [WidgetConfig] = []

    init() {
        loadWidgets()
    }

    func loadWidgets() {
        guard let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
              let saved = try? JSONDecoder().decode([WidgetConfig].self, from: data),
              !saved.isEmpty else {
            widgets = Self.defaultWidgets()
            saveWidgets()
            return
        }
        widgets = saved
    }

    func saveWidgets() {
        guard let data = try? JSONEncoder().encode(widgets) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }

    func addWidget(_ config: WidgetConfig) {
        var config = config
        config.sortOrder = widgets.count
        widgets.append(config)
        saveWidgets()
    }

    func removeWidget(id: UUID) {
        widgets.removeAll { $0.id == id }
        reindex()
        saveWidgets()
    }

    func moveWidget(from source: IndexSet, to destination: Int) {
        widgets.move(fromOffsets: source, toOffset: destination)
        reindex()
        saveWidgets()
    }

    func updateWidget(_ config: WidgetConfig) {
        guard let index = widgets.firstIndex(where: { $0.id == config.id }) else { return }
        widgets[index] = config
        saveWidgets()
    }

    private func reindex() {
        for index in widgets.indices {
            widgets[index].sortOrder = index
        }
    }

    private static func defaultWidgets() -> [WidgetConfig] {
        [
            WidgetConfig(type: .gauge, dataSource: .health, title: "System Health", sortOrder: 0),
            WidgetConfig(type: .sparkline, dataSource: .insights, title: "Session Trend", sortOrder: 1),
            WidgetConfig(type: .list, dataSource: .crons, title: "Recent Cron Jobs", sortOrder: 2),
            WidgetConfig(type: .multiStat, dataSource: .insights, title: "Insights", sortOrder: 3),
            WidgetConfig(type: .barChart, dataSource: .insights, title: "Activity by Day", sortOrder: 4),
            WidgetConfig(type: .list, dataSource: .alerts, title: "Alerts", sortOrder: 5)
        ]
    }
}