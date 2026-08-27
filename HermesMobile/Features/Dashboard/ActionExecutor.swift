import Foundation

/// Executes a `HermesAction` against the Hermes server and publishes the
/// progress/outcome via `state`, so a single-action UI surface can observe it.
@MainActor
@Observable
final class ActionExecutor {
    private let provider: any DashboardDataProvider

    enum ExecutionState: Equatable {
        case idle
        case running(actionId: String)
        case success(actionId: String, message: String)
        case error(actionId: String, message: String)
    }

    private(set) var state: ExecutionState = .idle

    init(provider: any DashboardDataProvider) {
        self.provider = provider
    }

    func execute(_ action: HermesAction) async {
        state = .running(actionId: action.id)

        do {
            switch action.source {
            case .cron(let jobId):
                let result = try await provider.runCron(jobID: jobId)
                if result.ok == true {
                    state = .success(actionId: action.id, message: "\(action.name) started")
                } else {
                    state = .error(actionId: action.id, message: result.error ?? "Failed to run cron")
                }

            case .command(let name):
                _ = try await provider.execCommand(name: name)
                state = .success(actionId: action.id, message: "\(action.name) executed")

            case .skill(let name):
                let session = try await provider.createSession(
                    workspace: nil,
                    model: nil,
                    modelProvider: nil,
                    profile: nil
                )
                guard let sessionId = session.session?.sessionId else {
                    state = .error(actionId: action.id, message: "Failed to create session")
                    return
                }
                let prompt = "Use the \(name) skill to help investigate and resolve the current issue."
                _ = try await provider.startChat(
                    sessionID: sessionId,
                    message: prompt,
                    workspace: nil,
                    model: nil
                )
                state = .success(actionId: action.id, message: "AI session started for \(action.name)")
            }
        } catch {
            state = .error(actionId: action.id, message: error.localizedDescription)
        }
    }

    func clearState() {
        state = .idle
    }
}