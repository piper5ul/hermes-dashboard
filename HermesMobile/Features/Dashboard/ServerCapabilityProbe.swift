import Foundation
import Observation

/// Meta-level capability detection for the connected hermes-webui server.
///
/// Intentionally bypasses `DashboardDataProvider`/`APIClient` — it talks to the
/// server directly so widgets can degrade gracefully when a data-source endpoint
/// simply doesn't exist on an older server. Uses `URLSession.shared` so the
/// app's existing auth cookies are attached when already signed in, but never
/// injects the user's custom headers; if the server still requires auth
/// (401/403) the probe bails and keeps the optimistic `.unknown` default.
@MainActor
@Observable
final class ServerCapabilityProbe {
    private let baseURL: URL
    private let session: URLSession
    private(set) var capabilities: ServerCapabilities = .unknown
    private(set) var hasProbed = false

    init(baseURL: URL) {
        self.baseURL = baseURL
        self.session = .shared
    }

    func probe() async {
        guard let settings = await fetchSettings() else {
            // Auth-gated server or a settings failure: we can't probe freely, so
            // keep `.unknown` (all features on) and let widgets render anyway.
            hasProbed = true
            return
        }

        async let health = endpointExists(path: "/api/system/health")
        async let insights = endpointExists(path: "/api/insights")
        async let crons = endpointExists(path: "/api/crons")
        async let skills = endpointExists(path: "/api/skills")
        async let approvals = endpointExists(path: "/api/approval/pending")
        async let kanban = endpointExists(path: "/api/kanban/boards")

        capabilities = ServerCapabilities(
            webuiVersion: settings.webuiVersion,
            agentVersion: settings.agentVersion,
            authEnabled: settings.authEnabled ?? false,
            passkeysEnabled: settings.passkeysEnabled ?? false,
            oidcEnabled: settings.oidcEnabled ?? false,
            hasInsights: await insights,
            hasCrons: await crons,
            hasSkills: await skills,
            hasApprovals: await approvals,
            hasKanban: await kanban,
            hasSystemHealth: await health
        )
        hasProbed = true
    }

    /// `GET /api/settings`. Returns nil when the server needs auth we don't
    /// have (401/403) or the request/parse fails — both mean callers should keep
    /// the default `.unknown`.
    private func fetchSettings() async -> ServerSettingsSnapshot? {
        var request = URLRequest(url: baseURL.appending(path: "/api/settings"))
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  http.statusCode == 200 else {
                return nil
            }
            return try? JSONDecoder().decode(ServerSettingsSnapshot.self, from: data)
        } catch {
            return nil
        }
    }

    /// Lightweight GET existence check. A definitive 404/410 means the endpoint
    /// is missing; any other outcome (auth, server error, network failure) is
    /// inconclusive and reports true so widgets keep their optimistic default.
    private func endpointExists(path: String) async -> Bool {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (_, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return true }
            switch http.statusCode {
            case 200...299:
                return true
            case 404, 410:
                return false
            default:
                return true
            }
        } catch {
            return true
        }
    }
}

/// Narrow tolerant slice of `GET /api/settings`, decoded only for capability
/// detection. The server returns ~75 keys; missing ones decode as nil and we
/// never crash on an unexpected shape.
private struct ServerSettingsSnapshot: Decodable, Sendable {
    let webuiVersion: String?
    let agentVersion: String?
    let authEnabled: Bool?
    let passkeysEnabled: Bool?
    let oidcEnabled: Bool?

    enum CodingKeys: String, CodingKey {
        case webuiVersion = "webui_version"
        case agentVersion = "agent_version"
        case authEnabled = "auth_enabled"
        case passkeysEnabled = "passkeys_enabled"
        case oidcEnabled = "oidc_enabled"
    }
}