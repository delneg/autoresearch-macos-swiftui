import SwiftUI

struct LogView: View {
    @Environment(AppState.self) private var appState
    @State private var autoScroll = true

    private var logEntries: [LogLine] {
        appState.logLines.enumerated().map { LogLine(id: $0.offset, text: $0.element) }
    }

    var body: some View {
        VStack(spacing: 0) {
            LogToolbarView(autoScroll: $autoScroll)
            Divider()
            LogContentView(logEntries: logEntries, autoScroll: autoScroll)
        }
        .navigationTitle("Logs (\(appState.logLines.count) lines)")
    }
}

struct LogToolbarView: View {
    @Environment(AppState.self) private var appState
    @Binding var autoScroll: Bool

    var body: some View {
        HStack {
            Toggle("Auto-scroll", isOn: $autoScroll)
                .toggleStyle(.switch)
                .controlSize(.small)

            Spacer()

            Button("Copy All", systemImage: "doc.on.doc") {
                copyLog()
            }
            .buttonStyle(.borderless)
            .disabled(appState.logLines.isEmpty)

            Button("Clear", systemImage: "trash", action: appState.clearLog)
                .buttonStyle(.borderless)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func copyLog() {
        let text = appState.logLines.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

struct LogContentView: View {
    let logEntries: [LogLine]
    let autoScroll: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(logEntries) { entry in
                        Text(entry.text)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 1)
                            .id(entry.id)
                    }
                }
            }
            .background(.black.opacity(0.05))
            .onChange(of: logEntries.count) { _, newCount in
                if autoScroll, newCount > 0 {
                    proxy.scrollTo(newCount - 1, anchor: .bottom)
                }
            }
        }
    }
}
