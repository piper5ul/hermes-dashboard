import Foundation

extension APIClient {
    func pendingApprovals(sessionID: String) async throws -> [ApprovalRequest] {
        try await send(endpoint: .approvalPending(sessionID: sessionID), method: "GET")
    }

    func respondToApproval(approvalId: String, sessionId: String, choice: String) async throws {
        struct Body: Encodable {
            let approvalId: String
            let sessionId: String
            let choice: String
            enum CodingKeys: String, CodingKey {
                case approvalId = "approval_id"
                case sessionId = "session_id"
                case choice
            }
        }
        let _: EmptyResponse = try await send(
            endpoint: .approvalRespond,
            method: "POST",
            body: Body(approvalId: approvalId, sessionId: sessionId, choice: choice)
        )
    }
}

private struct EmptyResponse: Decodable {}
