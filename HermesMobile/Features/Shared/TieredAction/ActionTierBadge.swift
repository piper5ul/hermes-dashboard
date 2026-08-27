import SwiftUI

struct ActionTierBadge: View {
    let tier: ActionTier
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))
            Text(tier.label)
                .font(.system(size: 9, weight: .bold))
                .textCase(.uppercase)
                .tracking(0.5)
            if tier.isFree {
                Text("Free")
                    .font(.system(size: 9, weight: .bold))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor.opacity(0.12))
        .foregroundStyle(foregroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    private var icon: String {
        switch tier {
        case .runbook: "bolt.fill"
        case .ai: "sparkles"
        case .hybrid: "arrow.triangle.2.circlepath"
        }
    }
    
    private var backgroundColor: Color {
        switch tier {
        case .runbook: .green
        case .ai: .purple
        case .hybrid: .orange
        }
    }
    
    private var foregroundColor: Color { backgroundColor }
}