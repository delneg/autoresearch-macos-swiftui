import SwiftUI

struct HyperparamRow: View {
    let name: String
    let value: String

    var body: some View {
        HStack {
            Text(name)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.body.monospaced())
        }
        .padding(.vertical, 4)
    }
}
