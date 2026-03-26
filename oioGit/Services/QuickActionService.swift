import AppKit

enum QuickActionService {

    static func openTerminal(at directory: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Terminal", directory.path]
        try? process.run()
    }

    static func openIDE(
        at directory: URL, ide: String = "Visual Studio Code"
    ) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", ide, directory.path]
        try? process.run()
    }

    static func copyToClipboard(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }

    static func openInFinder(at directory: URL) {
        NSWorkspace.shared.selectFile(
            nil, inFileViewerRootedAtPath: directory.path
        )
    }
}
