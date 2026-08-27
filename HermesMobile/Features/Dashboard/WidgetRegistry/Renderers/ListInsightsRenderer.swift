import SwiftUI

struct ListInsightsRenderer: WidgetRenderer {
    static var supportedType: WidgetType = .list
    static var supportedSource: WidgetDataSource = .insights

    @MainActor @ViewBuilder
    static func render(config: WidgetConfig, context: WidgetRenderContext) -> some View {
        if let insights = context.insights {
            InsightsSummaryCard(insights: insights)
        }
    }
}