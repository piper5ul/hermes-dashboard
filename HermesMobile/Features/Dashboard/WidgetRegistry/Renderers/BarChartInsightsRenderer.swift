import SwiftUI

struct BarChartInsightsRenderer: WidgetRenderer {
    static var supportedType: WidgetType = .barChart
    static var supportedSource: WidgetDataSource = .insights

    @MainActor @ViewBuilder
    static func render(config: WidgetConfig, context: WidgetRenderContext) -> some View {
        if let insights = context.insights {
            let items: [(label: String, value: Double, color: Color)] = (insights.activityByDay ?? []).compactMap { day in
                guard let name = day.day, let sessions = day.sessions else { return nil }
                return (label: String(name.prefix(3)), value: Double(sessions), color: .accentColor)
            }
            BarChartWidgetView(items: items)
        }
    }
}