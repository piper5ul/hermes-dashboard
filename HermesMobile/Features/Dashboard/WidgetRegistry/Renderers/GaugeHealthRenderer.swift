import SwiftUI

struct GaugeHealthRenderer: WidgetRenderer {
    static var supportedType: WidgetType = .gauge
    static var supportedSource: WidgetDataSource = .health

    @MainActor @ViewBuilder
    static func render(config: WidgetConfig, context: WidgetRenderContext) -> some View {
        if let health = context.health {
            NavigationLink {
                HealthDetailView(health: health)
            } label: {
                GaugeWidgetView(health: health)
            }
            .buttonStyle(.plain)
        }
    }
}