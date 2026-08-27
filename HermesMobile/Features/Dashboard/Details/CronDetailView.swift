import SwiftUI

struct CronDetailView: View {
    let job: CronJob

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                JobInfoCard(job: job)

                RunbookActionCard(action: runNowAction)
            }
            .padding()
        }
        .navigationTitle(job.name ?? job.id)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var runNowAction: ActionDefinition {
        ActionDefinition(
            id: "run-now-\(job.id)",
            title: "Run Now",
            description: "Trigger the scheduled job and verify completion.",
            tier: .runbook,
            steps: [
                RunbookStep(id: "trigger", label: "Triggering job", commandHint: nil),
                RunbookStep(id: "wait", label: "Waiting for completion", commandHint: nil),
                RunbookStep(id: "verify", label: "Verifying output", commandHint: nil)
            ]
        )
    }
}

private struct JobInfoCard: View {
    let job: CronJob

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            infoRow(
                label: "Schedule",
                value: job.scheduleDisplay ?? "No schedule"
            )

            Divider()

            infoRow(
                label: "Last Run",
                value: job.lastRunAt?.formatted ?? "Never",
                statusColor: lastStatusColor
            )

            Divider()

            infoRow(
                label: "Next Run",
                value: job.nextRunAt?.formatted ?? "Not scheduled"
            )
        }
        .cardStyle()
    }

    private func infoRow(
        label: String,
        value: String,
        statusColor: Color? = nil
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundStyle(statusColor ?? .primary)
                .multilineTextAlignment(.trailing)
        }
    }

    private var lastStatusColor: Color? {
        guard let lastStatus = job.lastStatus else { return nil }
        switch lastStatus {
        case "error", "failed":
            return .red
        case "completed", "success":
            return .green
        default:
            return nil
        }
    }
}

