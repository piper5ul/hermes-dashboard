import Foundation

extension WidgetRendererRegistry {
    static func registerAll() {
        let registry = WidgetRendererRegistry.shared
        registry.register(GaugeHealthRenderer.self)
        registry.register(SparklineInsightsRenderer.self)
        registry.register(AreaChartInsightsRenderer.self)
        registry.register(BarChartInsightsRenderer.self)
        registry.register(StatCardInsightsRenderer.self)
        registry.register(StatCardHealthRenderer.self)
        registry.register(MultiStatInsightsRenderer.self)
        registry.register(HeatmapInsightsRenderer.self)
        registry.register(ListHealthRenderer.self)
        registry.register(ListAlertsRenderer.self)
        registry.register(ListCronsRenderer.self)
        registry.register(ListInsightsRenderer.self)
    }
}