import SwiftUI

struct SparklineInsightsRenderer: WidgetRenderer {
    static var supportedType: WidgetType = .sparkline
    static var supportedSource: WidgetDataSource = .insights

    @MainActor @ViewBuilder
    static func render(config: WidgetConfig, context: WidgetRenderContext) -> some View {
        if let insights = context.insights {
            let points = (insights.dailyTokens ?? []).compactMap { day in
                day.sessions.map { Double($0) }
            }
            SparklineWidgetView(
                dataPoints: points,
                title: config.title,
                currentValue: insights.totalSessions.map(String.init) ?? "—"
            )
        }
    }
}

/// (.areaChart, .insights) renders the same session trend as the sparkline.
struct AreaChartInsightsRenderer: WidgetRenderer {
    static var supportedType: WidgetType = .areaChart
    static var supportedSource: WidgetDataSource = .insights

    @MainActor @ViewBuilder
    static func render(config: WidgetConfig, context: WidgetRenderContext) -> some View {
        if let insights = context.insights {
            let points = (insights.dailyTokens ?? []).compactMap { day in
                day.sessions.map { Double($0) }
            }
            SparklineWidgetView(
                dataPoints: points,
                title: config.title,
                currentValue: insights.totalSessions.map(String.init) ?? "—"
            )
        }
    }
}