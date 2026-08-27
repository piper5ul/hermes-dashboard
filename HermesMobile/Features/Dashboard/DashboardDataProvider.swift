import Foundation

/// Protocol-based boundary between the Dashboard feature and the concrete
/// `APIClient`. Upstream changes to `APIClient` signatures break only
/// `APIClientDashboardAdapter`, not the dashboard feature files.
@MainActor
protocol DashboardDataProvider: Sendable {
    func fetchHealth() async throws -> SystemHealth
    func fetchSkills() async throws -> SkillsResponse
    func fetchCrons() async throws -> CronJobsResponse
    func fetchInsights(days: Int) async throws -> InsightsResponse
    func runCron(jobID: String) async throws -> CronMutationResponse
    func execCommand(name: String) async throws -> CommandExecResponse
    func createSession(workspace: String?, model: String?, modelProvider: String?, profile: String?) async throws -> SessionResponse
    func startChat(sessionID: String, message: String, workspace: String?, model: String?) async throws -> ChatStartResponse
    func respondToApproval(approvalId: String, sessionId: String, choice: String) async throws
}

@MainActor
final class APIClientDashboardAdapter: DashboardDataProvider {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchHealth() async throws -> SystemHealth {
        try await client.systemHealth()
    }

    func fetchSkills() async throws -> SkillsResponse {
        try await client.skills()
    }

    func fetchCrons() async throws -> CronJobsResponse {
        try await client.crons()
    }

    func fetchInsights(days: Int) async throws -> InsightsResponse {
        try await client.insights(days: days)
    }

    func runCron(jobID: String) async throws -> CronMutationResponse {
        try await client.runCron(jobID: jobID)
    }

    func execCommand(name: String) async throws -> CommandExecResponse {
        try await client.execCommand(name: name)
    }

    func createSession(workspace: String?, model: String?, modelProvider: String?, profile: String?) async throws -> SessionResponse {
        try await client.createSession(
            workspace: workspace,
            model: model,
            modelProvider: modelProvider,
            profile: profile
        )
    }

    func startChat(sessionID: String, message: String, workspace: String?, model: String?) async throws -> ChatStartResponse {
        try await client.startChat(
            sessionID: sessionID,
            message: message,
            workspace: workspace,
            model: model
        )
    }

    func respondToApproval(approvalId: String, sessionId: String, choice: String) async throws {
        try await client.respondToApproval(
            approvalId: approvalId,
            sessionId: sessionId,
            choice: choice
        )
    }
}