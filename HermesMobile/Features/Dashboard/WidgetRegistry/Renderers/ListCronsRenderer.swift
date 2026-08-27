import SwiftUI

struct ListCronsRenderer: WidgetRenderer {
    static var supportedType: WidgetType = .list
    static var supportedSource: WidgetDataSource = .crons

    @MainActor @ViewBuilder
    static func render(config: WidgetConfig, context: WidgetRenderContext) -> some View {
        CronJobsCard(jobs: context.recentCrons?.jobs ?? [])
    }
}