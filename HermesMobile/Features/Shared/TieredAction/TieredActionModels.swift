import Foundation

enum ActionTier: String, Codable, Sendable {
    case runbook
    case ai
    case hybrid
    
    var label: String {
        switch self {
        case .runbook: "Runbook"
        case .ai: "AI-Assisted"
        case .hybrid: "Hybrid"
        }
    }
    
    var badgeColor: String {
        switch self {
        case .runbook: "green"
        case .ai: "purple"
        case .hybrid: "orange"
        }
    }
    
    var isFree: Bool { self == .runbook }
}

struct RunbookStep: Identifiable, Sendable {
    let id: String
    let label: String
    let commandHint: String?
    var status: StepStatus = .waiting
    var timestamp: Date?
    
    enum StepStatus: Sendable {
        case waiting, active, done, failed
    }
}

struct ActionDefinition: Identifiable, Sendable {
    let id: String
    let title: String
    let description: String
    let tier: ActionTier
    let estimatedTokens: Int?
    let estimatedCost: String?
    var steps: [RunbookStep]
    
    init(id: String, title: String, description: String, tier: ActionTier, estimatedTokens: Int? = nil, estimatedCost: String? = nil, steps: [RunbookStep] = []) {
        self.id = id
        self.title = title
        self.description = description
        self.tier = tier
        self.estimatedTokens = estimatedTokens
        self.estimatedCost = estimatedCost
        self.steps = steps
    }
}