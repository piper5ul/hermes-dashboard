import SwiftUI

struct HeatmapInsightsRenderer: WidgetRenderer {
    static var supportedType: WidgetType = .heatmap
    static var supportedSource: WidgetDataSource = .insights

    @MainActor @ViewBuilder
    static func render(config: WidgetConfig, context: WidgetRenderContext) -> some View {
        if let insights = context.insights {
            let hourData = (insights.activityByHour ?? []).compactMap { $0.sessions }
            let grid = stride(from: 0, to: hourData.count, by: 7).map { start in
                Array(hourData[start..<min(start + 7, hourData.count)])
            }
            HeatmapWidgetView(grid: grid.isEmpty ? [] : grid)
        }
    }
}