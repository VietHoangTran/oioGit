import SwiftUI

struct GitHubAccountSettingsView: View {
    @State private var tokenInput = ""
    @State private var status: TokenStatus = .checking
    @State private var showDeleteConfirm = false

    var body: some View {
        Form {
            Section("GitHub Personal Access Token") {
                tokenStatusView
                tokenInputSection
            }

            Section {
                Text("Token is stored securely in macOS Keychain.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Required scope: repo (for private repos) or public_repo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .task { checkExistingToken() }
    }

    @ViewBuilder
    private var tokenStatusView: some View {
        HStack {
            statusIcon
            Text(status.label)
                .font(.callout)
            Spacer()
            if status == .saved || status == .valid || status == .invalid {
                Button("Validate") {
                    Task { await validateToken() }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Delete", role: .destructive) {
                    showDeleteConfirm = true
                }
                .controlSize(.small)
                .alert("Delete GitHub Token?", isPresented: $showDeleteConfirm) {
                    Button("Delete", role: .destructive) { deleteToken() }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }

        if let masked = KeychainService.maskedToken(), status != .none {
            Text("Current: \(masked)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var tokenInputSection: some View {
        if status == .none || status == .invalid {
            HStack {
                SecureField("ghp_xxxxxxxxxxxx", text: $tokenInput)
                    .textFieldStyle(.roundedBorder)

                Button("Save") { saveToken() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(tokenInput.isEmpty)
            }
        }
    }

    private var statusIcon: some View {
        Group {
            switch status {
            case .none:
                Image(systemName: "circle.dashed")
                    .foregroundStyle(.secondary)
            case .checking, .validating:
                ProgressView().controlSize(.small)
            case .saved:
                Image(systemName: "checkmark.circle").foregroundStyle(.blue)
            case .valid:
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            case .invalid:
                Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
            }
        }
    }

    private func checkExistingToken() {
        status = KeychainService.exists() ? .saved : .none
    }

    private func saveToken() {
        do {
            try KeychainService.save(token: tokenInput)
            tokenInput = ""
            status = .saved
        } catch {
            status = .invalid
        }
    }

    private func deleteToken() {
        try? KeychainService.delete()
        tokenInput = ""
        status = .none
    }

    private func validateToken() async {
        status = .validating
        guard let token = KeychainService.retrieve() else {
            status = .none
            return
        }

        var request = URLRequest(url: URL(string: "https://api.github.com/user")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            status = httpResponse?.statusCode == 200 ? .valid : .invalid
        } catch {
            status = .invalid
        }
    }
}

private enum TokenStatus {
    case none, checking, saved, validating, valid, invalid

    var label: String {
        switch self {
        case .none: return "No token configured"
        case .checking: return "Checking..."
        case .saved: return "Token saved"
        case .validating: return "Validating..."
        case .valid: return "Token valid"
        case .invalid: return "Token invalid"
        }
    }
}

#Preview {
    GitHubAccountSettingsView()
        .frame(width: 450)
}
