import SwiftUI

struct AIActionCard: View {
    let action: ActionDefinition
    let onInvoke: () async -> Void
    @State private var isInvoking = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ActionTierBadge(tier: .ai)
            
            Text(action.title)
                .font(.headline)
            
            Text(action.description)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if let tokens = action.estimatedTokens {
                HStack(spacing: 4) {
                    Text("~\(tokens) tokens")
                        .font(.caption2.bold())
                        .foregroundStyle(.purple)
                    if let cost = action.estimatedCost {
                        Text("· \(cost) estimated")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Button {
                Task {
                    isInvoking = true
                    await onInvoke()
                    isInvoking = false
                }
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text(isInvoking ? "Working..." : action.title)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
            }
            .buttonStyle(.bordered)
            .tint(.purple)
            .disabled(isInvoking)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}