import Foundation

// Diagnostic errors — surfaced only in logs. The feedback flow is optimistic:
// the user always sees "thanks", and any failure here just leaves the entry in
// the local queue for a later retry (see FeedbackService). These strings never
// reach the UI, so they are intentionally not localized.
enum DriveFeedbackError: Error, LocalizedError {
    case notConfigured
    case authFailed(String)
    case folderFailed(String)
    case uploadFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Drive credentials not configured."
        case .authFailed(let detail): return "Auth error: \(detail)"
        case .folderFailed(let detail): return "Folder error: \(detail)"
        case .uploadFailed(let detail): return "Upload error: \(detail)"
        }
    }
}

// HTTP client for the anonymous feedback → Google Drive flow. A deliberately
// minimal subset of KarolPhotoBooth's DriveClient: OAuth token refresh,
// find-or-create-folder, and a single JSON-file create. No media upload, no
// listing, no deletion, no sharing, no multi-device sync — feedback is strictly
// one-way and one file per submission, so none of that machinery is needed.
//
// Actor so the cached access token + folder ids stay isolated without the
// MainActor (network work never touches the UI thread).
actor DriveFeedbackClient {
    private var accessToken: String?
    private var accessTokenExpiresAt: Date?
    private var rootFolderId: String?
    private var feedbackFolderId: String?

    private let session = URLSession.shared

    // Subfolder under the root folder where every feedback JSON lands.
    private let feedbackFolderName = "feedback"

    // MARK: - Public

    // Resolves (and caches) the "<raíz>/feedback" folder, then writes `data` as a
    // new JSON file. Returns the Drive file id. Throws `.notConfigured` if the
    // credentials are still placeholders.
    func uploadFeedback(filename: String, data: Data) async throws -> String {
        guard DriveCredentials.isConfigured else { throw DriveFeedbackError.notConfigured }
        let folderId = try await ensureFeedbackFolder()
        return try await createJSONFile(name: filename, parentId: folderId, data: data)
    }

    // MARK: - Token

    private func currentToken() async throws -> String {
        if let token = accessToken,
           let expiresAt = accessTokenExpiresAt,
           expiresAt.timeIntervalSinceNow > 60 {
            return token
        }
        return try await refreshToken()
    }

    private func refreshToken() async throws -> String {
        guard let url = URL(string: "https://oauth2.googleapis.com/token") else {
            throw DriveFeedbackError.authFailed("invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var form = URLComponents()
        form.queryItems = [
            URLQueryItem(name: "client_id", value: DriveCredentials.clientId),
            URLQueryItem(name: "client_secret", value: DriveCredentials.clientSecret),
            URLQueryItem(name: "refresh_token", value: DriveCredentials.refreshToken),
            URLQueryItem(name: "grant_type", value: "refresh_token")
        ]
        request.httpBody = form.percentEncodedQuery?.data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw DriveFeedbackError.authFailed("non-HTTP response")
        }
        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw DriveFeedbackError.authFailed("status \(http.statusCode) — \(body)")
        }

        struct TokenResponse: Decodable {
            let access_token: String
            let expires_in: Int
        }
        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        accessToken = decoded.access_token
        accessTokenExpiresAt = Date().addingTimeInterval(TimeInterval(decoded.expires_in))
        return decoded.access_token
    }

    // MARK: - Folders

    // "<raíz>/feedback", cached after first resolve.
    private func ensureFeedbackFolder() async throws -> String {
        if let cached = feedbackFolderId { return cached }
        let rootId = try await ensureRootFolder()
        let id = try await findOrCreateFolder(name: feedbackFolderName, parentId: rootId)
        feedbackFolderId = id
        return id
    }

    // Root folder in My Drive (DriveCredentials.rootFolderName). With scope drive.file we only ever see
    // folders this OAuth client created, so this never clashes with Karol's
    // "KarolPhotoBooth" root even though both apps share the credentials.
    private func ensureRootFolder() async throws -> String {
        if let cached = rootFolderId { return cached }
        let id = try await findOrCreateFolder(name: DriveCredentials.rootFolderName, parentId: nil)
        rootFolderId = id
        return id
    }

    private func findOrCreateFolder(name: String, parentId: String?) async throws -> String {
        if let existing = try await findFolder(name: name, parentId: parentId) {
            return existing
        }
        return try await createFolder(name: name, parentId: parentId)
    }

    private func findFolder(name: String, parentId: String?) async throws -> String? {
        let token = try await currentToken()
        let escapedName = name.replacingOccurrences(of: "'", with: "\\'")
        var query = "mimeType = 'application/vnd.google-apps.folder'"
            + " and name = '\(escapedName)'"
            + " and trashed = false"
        if let parentId {
            query += " and '\(parentId)' in parents"
        }

        var components = URLComponents(string: "https://www.googleapis.com/drive/v3/files")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "spaces", value: "drive"),
            URLQueryItem(name: "fields", value: "files(id,name)")
        ]
        var request = URLRequest(url: components.url!)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw DriveFeedbackError.folderFailed("find status \(status) — \(body)")
        }
        struct FilesListResponse: Decodable {
            struct File: Decodable { let id: String }
            let files: [File]
        }
        return try JSONDecoder().decode(FilesListResponse.self, from: data).files.first?.id
    }

    private func createFolder(name: String, parentId: String?) async throws -> String {
        let token = try await currentToken()
        var request = URLRequest(url: URL(string: "https://www.googleapis.com/drive/v3/files")!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "name": name,
            "mimeType": "application/vnd.google-apps.folder"
        ]
        if let parentId {
            body["parents"] = [parentId]
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let errBody = String(data: data, encoding: .utf8) ?? ""
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw DriveFeedbackError.folderFailed("create status \(status) — \(errBody)")
        }
        struct CreateResponse: Decodable { let id: String }
        return try JSONDecoder().decode(CreateResponse.self, from: data).id
    }

    // MARK: - Upload

    // Multipart create of a JSON file (metadata part + content part). Feedback
    // payloads are tiny (a few hundred bytes), so the multipart path is always
    // fine — no resumable threshold logic needed.
    private func createJSONFile(name: String, parentId: String, data: Data) async throws -> String {
        let token = try await currentToken()
        let metadata: [String: Any] = ["name": name, "parents": [parentId]]
        let metadataData = try JSONSerialization.data(withJSONObject: metadata)
        let boundary = "toss-\(UUID().uuidString)"

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        body.append(metadataData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        let url = URL(string: "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (respData, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let errBody = String(data: respData, encoding: .utf8) ?? ""
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw DriveFeedbackError.uploadFailed("createJSONFile status \(status) — \(errBody)")
        }
        struct Resp: Decodable { let id: String }
        return try JSONDecoder().decode(Resp.self, from: respData).id
    }
}
