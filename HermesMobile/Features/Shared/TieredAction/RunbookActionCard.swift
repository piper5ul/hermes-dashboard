import SwiftUI

struct RunbookActionCard: View {
    let action: ActionDefinition

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ActionTierBadge(tier: .runbook)

            Text(action.title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(action.steps) { step in
                    HStack(spacing: 8) {
                        Image(systemName: icon(for: step.status))
                            .font(.caption2)
                            .foregroundStyle(color(for: step.status))

                        Text(step.label)
                            .font(.caption)
                            .foregroundStyle(step.status == .waiting ? Color.secondary : .primary)
                    }
                }
            }

            Button {
            } label: {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text(action.title)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
            }
            .buttonStyle(.bordered)
            .tint(.green)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func icon(for status: RunbookStep.StepStatus) -> String {
        switch status {
        case .waiting: "circle.dashed"
        case .active: "progress.indicator"
        case .done: "checkmark.circle.fill"
        case .failed: "xmark.circle.fill"
        }
    }

    private func color(for status: RunbookStep.StepStatus) -> Color {
        switch status {
        case .waiting: .secondary
        case .active: .green
        case .done: .green
        case .failed: .red
        }
    }
}