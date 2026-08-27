import Foundation

struct ServerCapabilities: Sendable {
    let webuiVersion: String?
    let agentVersion: String?
    let authEnabled: Bool
    let passkeysEnabled: Bool
    let oidcEnabled: Bool

    // Feature flags derived from version or probing
    let hasInsights: Bool
    let hasCrons: Bool
    let hasSkills: Bool
    let hasApprovals: Bool
    let hasKanban: Bool
    let hasSystemHealth: Bool

    static let unknown = ServerCapabilities(
        webuiVersion: nil, agentVersion: nil,
        authEnabled: false, passkeysEnabled: false, oidcEnabled: false,
        hasInsights: true, hasCrons: true, hasSkills: true,
        hasApprovals: true, hasKanban: true, hasSystemHealth: true
    )
}