import SwiftUI
import Charts

struct GaugeWidgetView: View {
    let health: SystemHealth?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Health")
                .font(.headline)

            if let health {
                HStack(spacing: 8) {
                    GaugeCell(
                        label: "CPU",
                        value: health.cpu?.percent
                    )
                    GaugeCell(
                        label: "Memory",
                        value: health.memory?.percent
                    )
                    GaugeCell(
                        label: "Disk",
                        value: health.disk?.percent
                    )
                }
            } else {
                Text("Unavailable")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }
}

private struct GaugeCell: View {
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

struct SparklineWidgetView: View {
    let dataPoints: [Double]
    let title: String
    let currentValue: String

    @State private var selectedX: Double?

    private var chartData: [(index: Int, value: Double)] {
        dataPoints.enumerated().map { (index: $0.offset, value: $0.element) }
    }

    private var displayedValue: String {
        guard let selectedX else { return currentValue }
        let index = clampIndex(Int(selectedX.rounded()))
        return String(format: "%.1f", chartData[index].value)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(displayedValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if chartData.isEmpty {
                Text("No data")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                Chart {
                    ForEach(chartData, id: \.index) { point in
                        AreaMark(
                            x: .value("Index", point.index),
                            y: .value("Value", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.35), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        LineMark(
                            x: .value("Index", point.index),
                            y: .value("Value", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color.accentColor)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                }
                .frame(height: 120)
                .chartXSelection(value: $selectedX)
            }
        }
        .cardStyle()
    }

    private func clampIndex(_ index: Int) -> Int {
        guard !chartData.isEmpty else { return 0 }
        return min(max(index, 0), chartData.count - 1)
    }
}

struct BarChartWidgetView: View {
    let items: [(label: String, value: Double, color: Color)]

    @State private var selectedLabel: String?

    private var selectedItem: (label: String, value: Double, color: Color)? {
        guard let selectedLabel else { return nil }
        return items.first { $0.label == selectedLabel }
    }

    private var summaryText: String {
        guard let selectedItem else {
            let total = items.reduce(0) { $0 + $1.value }
            return total == 0 ? "" : String(format: "Total: %.0f", total)
        }
        return String(format: "%@: %.0f", selectedItem.label, selectedItem.value)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Activity")
                    .font(.headline)
                Spacer()
                Text(summaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if items.isEmpty {
                Text("No data")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                Chart {
                    ForEach(items.indices, id: \.self) { index in
                        BarMark(
                            x: .value("Label", items[index].label),
                            y: .value("Value", items[index].value)
                        )
                        .foregroundStyle(items[index].color)
                    }
                }
                .frame(height: 140)
                .chartXSelection(value: $selectedLabel)
            }
        }
        .cardStyle()
    }
}

struct StatCardWidgetView: View {
    let value: String
    let delta: Double?
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if let delta, delta != 0 {
                    DeltaBadge(delta: delta)
                }
            }

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

private struct DeltaBadge: View {
    let delta: Double

    private var isPositive: Bool { delta > 0 }

    var body: some View {
        Label(
            String(format: "%.1f%%", abs(delta)),
            systemImage: isPositive ? "arrow.up.right" : "arrow.down.right"
        )
        .font(.caption.bold())
        .foregroundStyle(isPositive ? Color.green : Color.red)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule().fill((isPositive ? Color.green : Color.red).opacity(0.15))
        )
    }
}

struct MultiStatWidgetView: View {
    let stats: [(value: String, label: String)]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(stats.indices, id: \.self) { index in
                VStack(spacing: 4) {
                    Text(stats[index].value)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(.primary)
                    Text(stats[index].label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Color(.tertiarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 12)
                )
            }
        }
        .cardStyle()
    }
}

struct HeatmapWidgetView: View {
    let grid: [[Int]]

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 6),
        count: 7
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Heatmap")
                .font(.headline)

            if grid.isEmpty {
                Text("No data")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(grid.indices, id: \.self) { week in
                        ForEach(grid[week].indices, id: \.self) { day in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    Color.accentColor.opacity(
                                        opacity(for: grid[week][day])
                                    )
                                )
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    private func opacity(for value: Int) -> Double {
        0.1 + Double(min(max(value, 0), 4)) * 0.225
    }
}