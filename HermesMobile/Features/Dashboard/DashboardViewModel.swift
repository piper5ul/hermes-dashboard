import Foundation
import SwiftUI

@MainActor
@Observable
final class DashboardViewModel {
    private let provider: any DashboardDataProvider
    private let capabilityProbe: ServerCapabilityProbe

    var health: SystemHealth?
    var pendingApprovals: [ApprovalRequest] = []
    var recentCrons: CronJobsResponse?
    var insights: InsightsResponse?
    var isLoading = false
    var error: String?

    init(provider: any DashboardDataProvider, capabilityProbe: ServerCapabilityProbe) {
        self.provider = provider
        self.capabilityProbe = capabilityProbe
    }

    func loadAll() async {
        isLoading = true
        error = nil
        let capabilities = capabilityProbe.capabilities
        if capabilities.hasSystemHealth {
            async let h = try? provider.fetchHealth()
            health = await h
        } else {
            health = nil
        }
        if capabilities.hasCrons {
            async let c = try? provider.fetchCrons()
            recentCrons = await c
        } else {
            recentCrons = nil
        }
        if capabilities.hasInsights {
            async let i = try? provider.fetchInsights(days: 7)
            insights = await i
        } else {
            insights = nil
        }
        isLoading = false
    }

    func respondToApproval(_ approval: ApprovalRequest, choice: String) async {
        do {
            try await provider.respondToApproval(
                approvalId: approval.id,
                sessionId: approval.sessionId,
                choice: choice
            )
            pendingApprovals.removeAll { $0.id == approval.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
}