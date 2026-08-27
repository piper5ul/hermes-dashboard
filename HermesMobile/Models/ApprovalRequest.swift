import Foundation

struct ApprovalRequest: Codable, Sendable, Identifiable {
    let id: String
    let tool: String
    let sessionId: String
    let description: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case tool
        case sessionId = "session_id"
        case description
        case createdAt = "created_at"
    }
}