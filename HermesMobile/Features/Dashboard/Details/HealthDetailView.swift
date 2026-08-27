import SwiftUI

struct HealthDetailView: View {
    let health: SystemHealth

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if let cpu = health.cpu {
                    gaugeCard(
                        label: "CPU",
                        value: cpu.percent,
                        detail: cpu.cores.map { "\($0) cores" }
                    )
                }
                if let memory = health.memory {
                    gaugeCard(
                        label: "Memory",
                        value: memory.percent,
                        detail: byteSummary(memory.usedBytes, of: memory.totalBytes)
                    )
                }
                if let disk = health.disk {
                    gaugeCard(
                        label: "Disk",
                        value: disk.percent,
                        detail: byteSummary(disk.usedBytes, of: disk.totalBytes)
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Actions")
                        .font(.headline)
                    HStack(spacing: 8) {
                        Text("Restart Agent")
                        Spacer()
                        ActionTierBadge(tier: .runbook)
                    }
                }
                .cardStyle()
            }
            .padding()
        }
        .navigationTitle("System Health")
    }

    private func gaugeCard(label: String, value: Double?, detail: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
            if let value {
                Gauge(value: value, in: 0...100) {
                    Text(label)
                } currentValueLabel: {
                    Text("\(Int(value.rounded()))%")
                }
                .gaugeStyle(.accessoryLinear)
            } else {
                Text("Unavailable")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }

    private func byteSummary(_ used: Int?, of total: Int?) -> String? {
        guard let used, let total else { return nil }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return "\(formatter.string(fromByteCount: Int64(used))) / \(formatter.string(fromByteCount: Int64(total)))"
    }
}