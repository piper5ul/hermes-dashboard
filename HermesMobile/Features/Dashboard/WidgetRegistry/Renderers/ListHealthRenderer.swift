import SwiftUI

struct ListHealthRenderer: WidgetRenderer {
    static var supportedType: WidgetType = .list
    static var supportedSource: WidgetDataSource = .health

    @MainActor @ViewBuilder
    static func render(config: WidgetConfig, context: WidgetRenderContext) -> some View {
        if let health = context.health {
            NavigationLink {
                HealthDetailView(health: health)
            } label: {
                SystemHealthCard(health: health)
            }
            .buttonStyle(.plain)
        }
    }
}