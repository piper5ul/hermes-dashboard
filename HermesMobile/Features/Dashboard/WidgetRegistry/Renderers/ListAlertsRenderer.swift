import SwiftUI

struct ListAlertsRenderer: WidgetRenderer {
    static var supportedType: WidgetType = .list
    static var supportedSource: WidgetDataSource = .alerts

    @MainActor @ViewBuilder
    static func render(config: WidgetConfig, context: WidgetRenderContext) -> some View {
        ActiveAlertsCard(
            approvals: context.pendingApprovals,
            respond: context.respondToApproval
        )
    }
}