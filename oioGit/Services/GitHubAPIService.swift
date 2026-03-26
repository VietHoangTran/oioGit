import Foundation

enum GitHubAPIError: LocalizedError {
    case noToken
    case unauthorized
    case notFound
    case rateLimited
    case networkError(Error)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noToken: return "No GitHub token configured"
        case .unauthorized: return "GitHub token is invalid or expired"
        case .notFound: return "Repository or workflows not found"
        case .rateLimited: return "GitHub API rate limit exceeded"
        case .networkError(let error): return error.localizedDescription
        case .invalidResponse: return "Invalid response from GitHub API"
        }
    }
}

final class GitHubAPIService {
    static let shared = GitHubAPIService()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        session = URLSession(configuration: config)
    }

    func fetchLatestWorkflowRun(
        owner: String,
        repo: String,
        branch: String? = nil
    ) async throws -> CIStatus {
        guard let token = KeychainService.retrieve() else {
            throw GitHubAPIError.noToken
        }

        var urlString = "\(CIDefaults.githubAPIBase)/repos/\(owner)/\(repo)/actions/runs?per_page=1"
        if let branch {
            let encoded = branch.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed
            ) ?? branch
            urlString += "&branch=\(encoded)"
        }

        guard let url = URL(string: urlString) else {
            throw GitHubAPIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw GitHubAPIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200: break
        case 401: throw GitHubAPIError.unauthorized
        case 403: throw GitHubAPIError.rateLimited
        case 404: throw GitHubAPIError.notFound
        default: throw GitHubAPIError.invalidResponse
        }

        return try parseWorkflowRuns(data)
    }

    private func parseWorkflowRuns(_ data: Data) throws -> CIStatus {
        let decoded = try JSONDecoder().decode(WorkflowRunsResponse.self, from: data)

        guard let run = decoded.workflowRuns.first else {
            return .none
        }

        let state = mapConclusion(
            status: run.status,
            conclusion: run.conclusion
        )

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = dateFormatter.date(from: run.updatedAt)
            ?? ISO8601DateFormatter().date(from: run.updatedAt)

        return CIStatus(
            state: state,
            workflowName: run.name,
            lastRunDate: date,
            htmlURL: run.htmlURL
        )
    }

    private func mapConclusion(status: String, conclusion: String?) -> CIStatusState {
        switch status {
        case "queued", "waiting", "pending": return .pending
        case "in_progress": return .running
        case "completed":
            switch conclusion {
            case "success": return .success
            case "failure", "timed_out": return .failure
            case "cancelled": return .pending
            default: return .pending
            }
        default: return .pending
        }
    }
}

// MARK: - Minimal Codable response models

private struct WorkflowRunsResponse: Codable {
    let workflowRuns: [WorkflowRun]

    enum CodingKeys: String, CodingKey {
        case workflowRuns = "workflow_runs"
    }
}

private struct WorkflowRun: Codable {
    let name: String
    let status: String
    let conclusion: String?
    let updatedAt: String
    let htmlURL: String

    enum CodingKeys: String, CodingKey {
        case name, status, conclusion
        case updatedAt = "updated_at"
        case htmlURL = "html_url"
    }
}
