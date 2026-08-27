import SwiftUI

struct MultiStatInsightsRenderer: WidgetRenderer {
    static var supportedType: WidgetType = .multiStat
    static var supportedSource: WidgetDataSource = .insights

    @MainActor @ViewBuilder
    static func render(config: WidgetConfig, context: WidgetRenderContext) -> some View {
        if let insights = context.insights {
            MultiStatWidgetView(stats: [
                (value: insights.totalTokens.map(FormatUtils.tokens) ?? "—", label: "Tokens"),
                (value: insights.totalSessions.map(String.init) ?? "—", label: "Sessions"),
                (value: insights.totalCost.map { String(format: "$%.2f", $0) } ?? "—", label: "Cost")
            ])
        }
    }
}