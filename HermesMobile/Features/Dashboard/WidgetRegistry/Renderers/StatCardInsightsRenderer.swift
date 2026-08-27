import SwiftUI

struct StatCardInsightsRenderer: WidgetRenderer {
    static var supportedType: WidgetType = .statCard
    static var supportedSource: WidgetDataSource = .insights

    @MainActor @ViewBuilder
    static func render(config: WidgetConfig, context: WidgetRenderContext) -> some View {
        if let insights = context.insights {
            StatCardWidgetView(
                value: insights.totalTokens.map(FormatUtils.tokens) ?? "—",
                delta: nil,
                label: "Total Tokens (7d)"
            )
        }
    }
}