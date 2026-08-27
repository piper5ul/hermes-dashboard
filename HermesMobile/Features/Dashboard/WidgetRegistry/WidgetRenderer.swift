import SwiftUI

/// Context bag passed to every widget renderer so it can read whatever
/// dashboard data it needs without a direct ViewModel dependency.
struct WidgetRenderContext {
    let health: SystemHealth?
    let insights: InsightsResponse?
    let recentCrons: CronJobsResponse?
    let pendingApprovals: [ApprovalRequest]
    let respondToApproval: (ApprovalRequest, String) async -> Void
}

/// A type that knows how to render one (WidgetType, WidgetDataSource) combination.
protocol WidgetRenderer {
    /// The type+source pair this renderer handles.
    static var supportedType: WidgetType { get }
    static var supportedSource: WidgetDataSource { get }

    /// Build the widget view for the given config and context.
    associatedtype Body: View
    @MainActor @ViewBuilder
    static func render(config: WidgetConfig, context: WidgetRenderContext) -> Body
}

/// Registry of all widget renderers. Renderers register themselves at app launch.
@MainActor
final class WidgetRendererRegistry {
    static let shared = WidgetRendererRegistry()

    private var renderers: [(type: WidgetType, source: WidgetDataSource, render: @MainActor (WidgetConfig, WidgetRenderContext) -> AnyView)] = []

    /// Register a renderer. Called once per renderer type at app startup.
    func register<R: WidgetRenderer>(_ renderer: R.Type) {
        renderers.append((
            type: R.supportedType,
            source: R.supportedSource,
            render: { config, context in AnyView(R.render(config: config, context: context)) }
        ))
    }

    /// Find and invoke the best renderer for a config.
    /// Lookup order: exact (type, source) match first, then wildcard source match
    /// (any renderer whose source matches but type doesn't = fallback).
    func view(for config: WidgetConfig, context: WidgetRenderContext) -> AnyView {
        // Exact match
        if let exact = renderers.first(where: { $0.type == config.type && $0.source == config.dataSource }) {
            return exact.render(config, context)
        }
        // Source-only fallback (the old `(_, .health)` cases)
        if let fallback = renderers.first(where: { $0.source == config.dataSource && $0.type == .list }) {
            return fallback.render(config, context)
        }
        return AnyView(Text(config.title).font(.subheadline).foregroundStyle(.secondary))
    }
}
