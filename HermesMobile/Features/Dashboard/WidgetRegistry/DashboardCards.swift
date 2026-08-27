import SwiftUI

internal struct SystemHealthCard: View {
    let health: SystemHealth

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Health")
                .font(.headline)

            HStack {
                HealthGauge(
                    label: "CPU",
                    value: health.cpu?.percent
                )
                HealthGauge(
                    label: "Memory",
                    value: health.memory?.percent
                )
                HealthGauge(
                    label: "Disk",
                    value: health.disk?.percent
                )
            }
        }
        .cardStyle()
    }
}

internal struct HealthGauge: View {
    let label: String
    let value: Double?

    var body: some View {
        VStack(spacing: 6) {
            if let value {
                Gauge(value: value, in: 0...100) {
                    Text(label)
                } currentValueLabel: {
                    Text("\(Int(value.rounded()))%")
                        .font(.caption2)
                }
                .gaugeStyle(.accessoryCircular)
            } else {
                Gauge(value: 0, in: 0...100) {
                    Text(label)
                } currentValueLabel: {
                    Text("—")
                        .font(.caption2)
                }
                .gaugeStyle(.accessoryCircular)
                .opacity(0.4)
            }

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

internal struct ActiveAlertsCard: View {
    let approvals: [ApprovalRequest]
    let respond: (ApprovalRequest, String) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Alerts")
                    .font(.headline)

                Spacer()

                Text("\(approvals.count)")
                    .font(.caption.bold())
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.red.opacity(0.15)))
            }

            if approvals.isEmpty {
                Text("No pending approvals")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(approvals) { approval in
                    HStack(spacing: 12) {
                        Text(approval.tool)

                        Spacer()

                        Button("Approve") {
                            Task { await respond(approval, "once") }
                        }

                        Button("Deny", role: .destructive) {
                            Task { await respond(approval, "deny") }
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
}

internal struct CronJobsCard: View {
    let jobs: [CronJob]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cron Jobs")
                .font(.headline)

            if jobs.isEmpty {
                Text("No cron jobs")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(jobs) { job in
                    NavigationLink {
                        CronDetailView(job: job)
                    } label: {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(job.enabled == true ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(job.name ?? job.id)
                                    .font(.subheadline)

                                Text(job.scheduleDisplay ?? "No schedule")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer(minLength: 0)

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cardStyle()
    }
}

internal struct InsightsSummaryCard: View {
    let insights: InsightsResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline)

            HStack(spacing: 12) {
                InsightMetric(
                    label: "Tokens",
                    value: insights.totalTokens.map(FormatUtils.tokens) ?? "—"
                )
                InsightMetric(
                    label: "Sessions",
                    value: insights.totalSessions.map(String.init) ?? "—"
                )
                InsightMetric(
                    label: "Cost",
                    value: insights.totalCost.map { String(format: "$%.2f", $0) } ?? "—"
                )
            }
        }
        .cardStyle()
    }
}

internal struct InsightMetric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color(.secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 16)
            )
    }
}
