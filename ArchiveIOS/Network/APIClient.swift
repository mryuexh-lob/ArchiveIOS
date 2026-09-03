import Foundation

struct APIResponse {
    let statusCode: Int
    let body: String
}

enum APIError: LocalizedError {
    case invalidURL
    case http(Int, String)
    case decode(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:          return "服务器地址无效"
        case .http(_, let msg):    return msg
        case .decode(let m):       return m
        }
    }
}

/// 后端 REST 客户端（原生 URLSession + async/await，无任何第三方依赖）。
/// 鉴权头与安卓端一致：Authorization: <token>
struct APIClient {
    static let shared = APIClient()
    private let decoder = JSONDecoder()

    // MARK: - 底层请求
    private func request(method: String,
                         path: String,
                         token: String? = nil,
                         body: Data? = nil) async throws -> APIResponse {
        let base = TokenManager.serverURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: base + path) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        if let token = token { req.setValue(token, forHTTPHeaderField: "Authorization") }
        req.httpBody = body
        req.timeoutInterval = 15
        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        let text = String(data: data, encoding: .utf8) ?? ""
        return APIResponse(statusCode: code, body: text)
    }

    private func extractMessage(_ body: String) -> String? {
        guard let data = body.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let msg = obj["message"] as? String else { return nil }
        return msg
    }

    private func json(_ dict: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: dict)
    }

    // MARK: - 鉴权
    func login(username: String, password: String) async throws -> LoginResponse {
        let data = try json(["username": username, "password": password])
        let r = try await request(method: "POST", path: "/api/auth/login", body: data)
        guard r.statusCode == 200 else {
            throw APIError.http(r.statusCode, extractMessage(r.body) ?? "登录失败（HTTP \(r.statusCode)）")
        }
        return try decoder.decode(LoginResponse.self, from: Data(r.body.utf8))
    }

    func me() async throws -> UserInfo {
        let r = try await request(method: "GET", path: "/api/auth/me", token: TokenManager.token)
        guard r.statusCode == 200 else {
            throw APIError.http(r.statusCode, extractMessage(r.body) ?? "获取用户信息失败")
        }
        return try decoder.decode(UserInfo.self, from: Data(r.body.utf8))
    }

    /// 修改个人密码（保留 N1 弱口令缺陷：服务端不校验复杂度）
    func changePassword(old: String, new: String) async throws {
        let data = try json(["oldPassword": old, "newPassword": new])
        let r = try await request(method: "PUT", path: "/api/auth/me/password",
                                  token: TokenManager.token, body: data)
        guard r.statusCode == 200 else {
            throw APIError.http(r.statusCode, extractMessage(r.body) ?? "修改密码失败")
        }
    }

    // MARK: - 归档工单
    func archives(status: String?, docType: String?, keyword: String?) async throws -> [ArchiveTask] {
        var comps = URLComponents(string: "/api/archives")!
        var q: [URLQueryItem] = []
        if let s = status, !s.isEmpty { q.append(URLQueryItem(name: "status",  value: s)) }
        if let t = docType, !t.isEmpty { q.append(URLQueryItem(name: "docType", value: t)) }
        if let k = keyword, !k.isEmpty { q.append(URLQueryItem(name: "keyword", value: k)) }
        comps.queryItems = q.isEmpty ? nil : q
        let path = comps.string ?? "/api/archives"
        let r = try await request(method: "GET", path: path, token: TokenManager.token)
        guard r.statusCode == 200 else {
            throw APIError.http(r.statusCode, extractMessage(r.body) ?? "获取工单列表失败")
        }
        return try decoder.decode([ArchiveTask].self, from: Data(r.body.utf8))
    }

    func createArchive(_ fields: [String: Any]) async throws {
        let data = try json(fields)
        let r = try await request(method: "POST", path: "/api/archives",
                                  token: TokenManager.token, body: data)
        guard r.statusCode == 200 else {
            throw APIError.http(r.statusCode, extractMessage(r.body) ?? "创建工单失败")
        }
    }

    func archiveDetail(id: Int) async throws -> ArchiveTask {
        let r = try await request(method: "GET", path: "/api/archives/\(id)", token: TokenManager.token)
        guard r.statusCode == 200 else {
            throw APIError.http(r.statusCode, extractMessage(r.body) ?? "获取工单详情失败")
        }
        return try decoder.decode(ArchiveTask.self, from: Data(r.body.utf8))
    }

    /// 审核（N3：客户端不校验角色，直接调用接口）
    func reviewArchive(id: Int, action: String, comment: String) async throws {
        let data = try json(["action": action, "comment": comment])
        let r = try await request(method: "POST", path: "/api/archives/\(id)/review",
                                  token: TokenManager.token, body: data)
        guard r.statusCode == 200 else {
            throw APIError.http(r.statusCode, extractMessage(r.body) ?? "审核失败")
        }
    }

    /// 归档（N3：客户端不校验角色，直接调用接口）
    func archiveArchive(id: Int, action: String, comment: String,
                        archiveNo: String, archiveLocation: String) async throws {
        let data = try json(["action": action, "comment": comment,
                              "archiveNo": archiveNo, "archiveLocation": archiveLocation])
        let r = try await request(method: "POST", path: "/api/archives/\(id)/archive",
                                  token: TokenManager.token, body: data)
        guard r.statusCode == 200 else {
            throw APIError.http(r.statusCode, extractMessage(r.body) ?? "归档失败")
        }
    }

    /// 撤回（删除工单，仅申请人且待审核）
    func deleteArchive(id: Int) async throws {
        let r = try await request(method: "DELETE", path: "/api/archives/\(id)", token: TokenManager.token)
        guard r.statusCode == 200 else {
            throw APIError.http(r.statusCode, extractMessage(r.body) ?? "撤回失败")
        }
    }

    func reviewers() async throws -> [Reviewer] {
        let r = try await request(method: "GET", path: "/api/archives/reviewers", token: TokenManager.token)
        guard r.statusCode == 200 else {
            throw APIError.http(r.statusCode, extractMessage(r.body) ?? "获取审核员失败")
        }
        return try decoder.decode([Reviewer].self, from: Data(r.body.utf8))
    }

    func checkVersion() async throws -> AppVersion? {
        let r = try await request(method: "GET", path: "/api/version")
        guard r.statusCode == 200 else { throw APIError.http(r.statusCode, "获取版本失败") }
        return try? decoder.decode(AppVersion.self, from: Data(r.body.utf8))
    }
}
