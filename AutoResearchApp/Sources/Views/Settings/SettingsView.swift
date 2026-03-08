import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        Form {
            Section("Project") {
                LabeledContent("Directory") {
                    HStack {
                        Text(appState.projectDirectory.path)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundStyle(.secondary)

                        Button("Choose...") {
                            chooseDirectory()
                        }
                    }
                }
            }

            Section("Tools") {
                TextField("uv binary path", text: $state.uvPath)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 400, idealWidth: 480, minHeight: 160, idealHeight: 200)
    }

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select the autoresearch-macos project directory"

        if panel.runModal() == .OK, let url = panel.url {
            appState.projectDirectory = url
        }
    }
}
