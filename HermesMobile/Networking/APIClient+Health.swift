import Foundation

extension APIClient {
    func systemHealth() async throws -> SystemHealth {
        try await send(endpoint: .systemHealth, method: "GET")
    }
}