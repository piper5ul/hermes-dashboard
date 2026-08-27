import Foundation

struct SystemHealth: Codable, Sendable {
    let cpu: CPUInfo?
    let memory: MemoryInfo?
    let disk: DiskInfo?
    let activeStreams: Int?
    let activeSessions: Int?
    let uptime: TimeInterval?

    struct CPUInfo: Codable, Sendable {
        let percent: Double?
        let cores: Int?
        enum CodingKeys: String, CodingKey {
            case percent
            case cores
        }
    }
    struct MemoryInfo: Codable, Sendable {
        let usedBytes: Int?
        let totalBytes: Int?
        let percent: Double?
        enum CodingKeys: String, CodingKey {
            case usedBytes = "used_bytes"
            case totalBytes = "total_bytes"
            case percent
        }
    }
    struct DiskInfo: Codable, Sendable {
        let usedBytes: Int?
        let totalBytes: Int?
        let percent: Double?
        enum CodingKeys: String, CodingKey {
            case usedBytes = "used_bytes"
            case totalBytes = "total_bytes"
            case percent
        }
    }
    enum CodingKeys: String, CodingKey {
        case cpu, memory, disk
        case activeStreams = "active_streams"
        case activeSessions = "active_sessions"
        case uptime
    }
}