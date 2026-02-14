import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Config info section
                configSection

                Divider()

                // Action buttons
                buttonSection

                Divider()

                // Log output
                logSection
            }
            .navigationTitle("MWDAT Bug Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var configSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MWDAT Plist Values")
                .font(.headline)

            Group {
                infoRow("MetaAppID", viewModel.plistValues["MetaAppID"] ?? "?")
                infoRow("ClientToken", viewModel.plistValues["ClientToken"] ?? "?")
                infoRow("TeamID", viewModel.plistValues["TeamID"] ?? "?")
            }

            Divider()

            if let err = viewModel.configureError {
                Label("Configure error: \(err)", systemImage: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            } else {
                Label("Configure: OK", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }

            HStack {
                Text("Registration:")
                    .font(.caption)
                Text(viewModel.registrationState)
                    .font(.caption.bold())
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var buttonSection: some View {
        HStack(spacing: 16) {
            Button(action: { viewModel.register() }) {
                Label("Register", systemImage: "person.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button(action: { viewModel.unregister() }) {
                Label("Unregister", systemImage: "person.badge.minus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Logs")
                    .font(.headline)
                Spacer()
                Button("Clear") {
                    viewModel.logs.removeAll()
                }
                .font(.caption)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(viewModel.logs.enumerated()), id: \.offset) { index, entry in
                            Text(entry)
                                .font(.system(.caption2, design: .monospaced))
                                .id(index)
                        }
                    }
                }
                .onChange(of: viewModel.logs.count) { _ in
                    if let last = viewModel.logs.indices.last {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemGroupedBackground))
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\"\(value)\"")
                .font(.system(.caption, design: .monospaced))
                .lineLimit(1)
        }
    }
}
