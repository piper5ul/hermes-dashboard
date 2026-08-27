import Foundation

/// The tagged payload backing a `HermesAction`'s `source`, with the shape
/// `{"type":"skill","name":"investigate"}`. `ActionTier` itself lives in
/// `Features/Shared/TieredAction/TieredActionModels.swift` and is reused here.
/// Decoding is tolerant: the discriminant is trimmed/lowercased, an unknown
/// `type` surfaces a descriptive error, and `cron` accepts both `jobId` and
/// `job_id` spellings upstream might send.
enum ActionSource: Codable, Equatable {
    case skill(name: String)
    case command(name: String)
    case cron(jobId: String)

    private enum CodingKeys: String, CodingKey {
        case type
        case name
        case jobId
        case jobIdSnake = "job_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = (try? container.decodeIfPresent(String.self, forKey: .type))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch type {
        case "skill":
            self = .skill(name: try container.decode(String.self, forKey: .name))
        case "command", "cmd":
            self = .command(name: try container.decode(String.self, forKey: .name))
        case "cron":
            let jobId = (try? container.decodeIfPresent(String.self, forKey: .jobId))
                ?? (try? container.decodeIfPresent(String.self, forKey: .jobIdSnake))
                ?? ""
            self = .cron(jobId: jobId)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown HermesAction source type \(type ?? "nil")"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .skill(name):
            try container.encode("skill", forKey: .type)
            try container.encode(name, forKey: .name)
        case let .command(name):
            try container.encode("command", forKey: .type)
            try container.encode(name, forKey: .name)
        case let .cron(jobId):
            try container.encode("cron", forKey: .type)
            try container.encode(jobId, forKey: .jobId)
        }
    }
}

/// A dashboard quick action surfaced from the server catalog: an AI skill, a
/// runbook command, or a scheduled cron job. `contexts` carries the
/// `WidgetDataSource` rawValues the action is relevant to, so a widget pane can
/// show only the actions that belong to it. `id` is source-prefixed
/// (`skill:investigate`, `cmd:restart`, `cron:abc123`).
struct HermesAction: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    let tier: ActionTier
    let source: ActionSource
    let category: String?
    let contexts: Set<String>
}

// MARK: - Factories

extension HermesAction {
    /// Maps a server skill into an AI action. Returns `nil` when the skill has
    /// no name (tolerant decode: a nameless skill cannot be invoked or keyed).
    static func from(skill: SkillSummary) -> HermesAction? {
        guard let name = normalized(skill.name) else { return nil }

        return HermesAction(
            id: "skill:\(name)",
            name: name,
            description: skill.description,
            tier: .ai,
            source: .skill(name: name),
            category: skill.category,
            contexts: contexts(name: skill.name, description: skill.description, category: skill.category)
        )
    }

    /// Maps a server command into a runbook action. Commands are general
    /// purpose, so they are relevant in every context. Returns `nil` when the
    /// command has no name.
    static func from(command: AgentCommand) -> HermesAction? {
        guard let name = normalized(command.name) else { return nil }

        return HermesAction(
            id: "cmd:\(name)",
            name: name,
            description: command.description,
            tier: .runbook,
            source: .command(name: name),
            category: command.category,
            contexts: allContexts
        )
    }

    /// Maps a cron job into a runbook action. Contexts always include `crons`;
    /// the job's `name` and `prompt` are scanned for vocabulary matching the
    /// other widget data sources. Returns `nil` when the job has no id (a job
    /// without an id cannot be keyed or addressed).
    static func from(cron: CronJob) -> HermesAction? {
        guard let jobId = normalized(cron.jobId) else { return nil }

        var contexts = contexts(name: cron.name, description: cron.prompt, category: nil)
        contexts.insert(WidgetDataSource.crons.rawValue)

        return HermesAction(
            id: "cron:\(jobId)",
            name: cron.name ?? jobId,
            description: cron.prompt,
            tier: .runbook,
            source: .cron(jobId: jobId),
            category: nil,
            contexts: contexts
        )
    }

    /// Keyword sets per widget data source. Extend a static array to teach a
    /// data source new vocabulary — no other code needs to change.
    private static let contextKeywords: [(source: WidgetDataSource, keywords: [String])] = [
        (
            WidgetDataSource.health,
            ["monitoring", "monitor", "health check", "health", "diagnostic",
             "diagnose", "system", "server status", "server", "status", "cpu",
             "memory", "disk", "uptime", "debug"]
        ),
        (
            WidgetDataSource.insights,
            ["analytics", "analytic", "reporting", "report", "metrics", "metric",
             "tokens", "token", "cost", "usage", "statistics", "statistic",
             "trend", "data analysis", "analyze", "analysis"]
        ),
        (
            WidgetDataSource.crons,
            ["scheduling", "schedule", "automation", "automate", "jobs", "job",
             "periodic", "recurring", "recur", "batch", "cron"]
        ),
        (
            WidgetDataSource.kanban,
            ["tasks", "task", "boards", "board", "project management", "project",
             "workflow", "cards", "card", "tickets", "ticket", "organize",
             "organise", "kanban"]
        ),
        (
            WidgetDataSource.sessions,
            ["chat", "conversation", "email", "mail", "ticket", "communication",
             "messaging", "message", "respond", "reply", "session"]
        ),
        (
            WidgetDataSource.alerts,
            ["notifications", "notification", "notify", "warnings", "warning",
             "approval", "approve", "security", "incident", "alert", "escalation",
             "escalate"]
        ),
    ]

    /// General-purpose contexts for skills that match no keyword set. Kept
    /// small (insights + sessions) rather than every data source so each widget
    /// stays meaningful.
    private static let defaultContexts: Set<String> = [
        WidgetDataSource.insights.rawValue,
        WidgetDataSource.sessions.rawValue,
    ]

    /// Context heuristic over name + description + category (all lowercased).
    /// A skill can match multiple data sources; one that matches none falls back
    /// to `defaultContexts` rather than every context.
    private static func contexts(name: String?, description: String?, category: String?) -> Set<String> {
        let haystack = [
            name?.lowercased(),
            description?.lowercased(),
            category?.lowercased(),
        ]
        .compactMap { $0 }
        .joined(separator: " ")

        guard !haystack.isEmpty else { return defaultContexts }

        let matched = contextKeywords.reduce(into: Set<String>()) { result, entry in
            if entry.keywords.contains(where: { haystack.contains($0) }) {
                result.insert(entry.source.rawValue)
            }
        }

        return matched.isEmpty ? defaultContexts : matched
    }

    /// Every `WidgetDataSource` rawValue — the default so nothing is hidden.
    private static var allContexts: Set<String> {
        Set(WidgetDataSource.allCases.map(\.rawValue))
    }

    /// Whitespace-trimmed value, or `nil` when blank.
    private static func normalized(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}