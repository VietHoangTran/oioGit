import SwiftUI

struct MiniDiffView: View {
    let filePath: String
    let isStaged: Bool
    let repoURL: URL

    @State private var diffLines: [DiffLine] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let gitRunner = GitCommandRunner.shared

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 40)
            } else if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(8)
            } else if diffLines.isEmpty {
                Text("No diff available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(8)
            } else {
                diffContent
            }
        }
        .task { await loadDiff() }
    }

    private var diffContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(
                    Array(diffLines.prefix(200).enumerated()),
                    id: \.offset
                ) { _, line in
                    Text(line.text)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(line.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(line.backgroundColor)
                }
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(4)
        .frame(maxHeight: 200)
    }

    private func loadDiff() async {
        isLoading = true
        var args = ["diff"]
        if isStaged { args.append("--cached") }
        args += ["--", filePath]

        do {
            let output = try await gitRunner.run(args, at: repoURL)
            diffLines = parseDiffOutput(output)
        } catch {
            errorMessage = "Could not load diff"
        }
        isLoading = false
    }

    private func parseDiffOutput(_ output: String) -> [DiffLine] {
        guard !output.isEmpty else { return [] }
        return output.components(separatedBy: "\n")
            .dropFirst(4) // Skip diff header lines
            .map { line in
                if line.hasPrefix("+") {
                    return DiffLine(text: line, type: .added)
                } else if line.hasPrefix("-") {
                    return DiffLine(text: line, type: .removed)
                } else if line.hasPrefix("@@") {
                    return DiffLine(text: line, type: .hunk)
                } else {
                    return DiffLine(text: line, type: .context)
                }
            }
    }
}

struct DiffLine {
    let text: String
    let type: DiffLineType

    var color: Color {
        switch type {
        case .added: return .green
        case .removed: return .red
        case .hunk: return .blue
        case .context: return .primary
        }
    }

    var backgroundColor: Color {
        switch type {
        case .added: return .green.opacity(0.1)
        case .removed: return .red.opacity(0.1)
        case .hunk: return .blue.opacity(0.05)
        case .context: return .clear
        }
    }
}

enum DiffLineType {
    case added, removed, hunk, context
}
