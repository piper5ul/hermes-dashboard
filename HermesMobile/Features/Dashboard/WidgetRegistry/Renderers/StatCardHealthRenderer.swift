import SwiftUI

struct StatCardHealthRenderer: WidgetRenderer {
    static var supportedType: WidgetType = .statCard
    static var supportedSource: WidgetDataSource = .health

    @MainActor @ViewBuilder
    static func render(config: WidgetConfig, context: WidgetRenderContext) -> some View {
        if let health = context.health {
            StatCardWidgetView(
                value: health.cpu?.percent.map { "\(Int($0.rounded()))%" } ?? "—",
                delta: nil,
                label: "CPU Usage"
            )
        }
    }
}