import SwiftUI
import SwiftData

struct RepoManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RepoConfig.dateAdded) private var repoConfigs: [RepoConfig]
    @State private var scanResults: [URL] = []
    @State private var showingScanSheet = false
    @State private var isScanning = false

    var body: some View {
        VStack(spacing: 0) {
            repoList
            Divider()
            bottomBar
        }
        .sheet(isPresented: $showingScanSheet) {
            ScanResultsSheet(
                results: scanResults,
                existingPaths: Set(repoConfigs.map(\.path)),
                onAdd: addScannedRepos
            )
        }
    }

    private var repoList: some View {
        List {
            ForEach(repoConfigs) { config in
                RepoConfigRow(config: config)
            }
            .onDelete(perform: deleteRepos)
        }
    }

    private var bottomBar: some View {
        HStack {
            Button("Scan Directory...") { scanDirectory() }
                .disabled(isScanning)
            if isScanning {
                ProgressView()
                    .controlSize(.small)
            }
            Spacer()
            Text("\(repoConfigs.count) repos")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
    }

    private func scanDirectory() {
        let panel = NSOpenPanel()
        panel.title = "Select Directory to Scan"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        isScanning = true
        Task.detached(priority: .userInitiated) {
            let results = RepoScannerService.scan(directory: url)
            await MainActor.run {
                self.scanResults = results
                self.isScanning = false
                if !results.isEmpty { self.showingScanSheet = true }
            }
        }
    }

    private func deleteRepos(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(repoConfigs[index])
        }
        try? modelContext.save()
    }

    private func addScannedRepos(_ urls: [URL]) {
        let existing = Set(repoConfigs.map(\.path))
        for url in urls where !existing.contains(url.path) {
            let bookmark = RepoConfig.createBookmark(for: url)
            let config = RepoConfig(path: url.path, bookmarkData: bookmark)
            modelContext.insert(config)
        }
        try? modelContext.save()
        showingScanSheet = false
    }
}

struct RepoConfigRow: View {
    @Bindable var config: RepoConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            TextField("Alias", text: aliasBinding, prompt: Text(defaultName))
                .font(.body)
            Text(config.path)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.vertical, 2)
    }

    private var defaultName: String {
        URL(fileURLWithPath: config.path).lastPathComponent
    }

    private var aliasBinding: Binding<String> {
        Binding(
            get: { config.alias ?? "" },
            set: { config.alias = $0.isEmpty ? nil : $0 }
        )
    }
}

struct ScanResultsSheet: View {
    let results: [URL]
    let existingPaths: Set<String>
    let onAdd: ([URL]) -> Void
    @State private var selected: Set<URL> = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Text("Found \(results.count) repositories")
                .font(.headline)

            List(newResults, id: \.path) { url in
                Toggle(url.lastPathComponent, isOn: toggleBinding(for: url))
            }
            .frame(height: 200)

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Add Selected (\(selected.count))") {
                    onAdd(Array(selected))
                }
                .disabled(selected.isEmpty)
            }
        }
        .padding()
        .frame(width: 360)
        .onAppear { selected = Set(newResults) }
    }

    private var newResults: [URL] {
        results.filter { !existingPaths.contains($0.path) }
    }

    private func toggleBinding(for url: URL) -> Binding<Bool> {
        Binding(
            get: { selected.contains(url) },
            set: { isOn in
                if isOn { selected.insert(url) }
                else { selected.remove(url) }
            }
        )
    }
}
