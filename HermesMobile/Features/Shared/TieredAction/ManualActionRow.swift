import SwiftUI

struct ManualActionRow: View {
    let label: String
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text("MANUAL")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .textCase(.uppercase)
                .tracking(1)
                .foregroundStyle(.secondary)
            Button(label) { action() }
                .font(.caption)
                .foregroundStyle(.secondary)
                .underline()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}