import SwiftUI

struct StatusBadge: View {
    let status: ExperimentResult.ExperimentStatus

    var body: some View {
        Text(status.label)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor, in: Capsule())
    }

    private var foregroundColor: Color {
        switch status {
        case .keep: .green
        case .discard: .red
        case .crash: .orange
        }
    }

    private var backgroundColor: Color {
        foregroundColor.opacity(0.15)
    }
}
