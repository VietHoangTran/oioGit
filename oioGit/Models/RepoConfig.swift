import Foundation
import SwiftData

@Model
final class RepoConfig {
    var path: String
    var alias: String?
    var bookmarkData: Data?
    var dateAdded: Date

    init(path: String, alias: String? = nil, bookmarkData: Data? = nil) {
        self.path = path
        self.alias = alias
        self.bookmarkData = bookmarkData
        self.dateAdded = Date()
    }

    var displayName: String {
        alias ?? URL(fileURLWithPath: path).lastPathComponent
    }

    var directoryURL: URL {
        URL(fileURLWithPath: path)
    }

    /// Resolve security-scoped bookmark and return accessible URL
    func resolveBookmark() -> URL? {
        guard let bookmarkData else { return nil }
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else { return nil }

        if isStale {
            // Bookmark needs refresh — caller should re-create
            return nil
        }
        return url
    }

    /// Create security-scoped bookmark from URL
    static func createBookmark(for url: URL) -> Data? {
        try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }
}
