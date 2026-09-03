import Foundation

/// 本地会话与配置管理。
///
/// ⚠️ 安全测试靶场样品（对应缺陷 N1：敏感数据本地明文存储）。
/// 口令、token、userId 均以明文写入 UserDefaults，key 与安卓端统一为 `saved_password`，
/// 便于测试人员通过 Xcode Devices 导出 App 容器查看 plist 直接看到口令明文。
struct TokenManager {
    private static let kToken    = "saved_token"
    private static let kUserId   = "saved_userId"
    private static let kUsername = "saved_username"
    private static let kRole     = "saved_role"
    private static let kServer   = "saved_server"
    private static let kPassword = "saved_password"   // N1：口令明文存储，key 与安卓端一致

    static var token: String? {
        get { UserDefaults.standard.string(forKey: kToken) }
        set { UserDefaults.standard.set(newValue, forKey: kToken) }
    }

    static var userId: Int? {
        get { UserDefaults.standard.string(forKey: kUserId).flatMap { Int($0) } }
        set { UserDefaults.standard.set(newValue.map { String($0) }, forKey: kUserId) }
    }

    static var username: String? {
        get { UserDefaults.standard.string(forKey: kUsername) }
        set { UserDefaults.standard.set(newValue, forKey: kUsername) }
    }

    static var role: String? {
        get { UserDefaults.standard.string(forKey: kRole) }
        set { UserDefaults.standard.set(newValue, forKey: kRole) }
    }

    /// 服务器地址：默认不写死（空串），首次启动请在登录页 / 「我的-服务器设置」中填写实际后端地址。
    static var serverURL: String {
        get { UserDefaults.standard.string(forKey: kServer) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: kServer) }
    }

    // N1：口令明文持久化（不加密、不存 Keychain）
    static var password: String? {
        get { UserDefaults.standard.string(forKey: kPassword) }
        set { UserDefaults.standard.set(newValue, forKey: kPassword) }
    }

    static func saveLogin(_ resp: LoginResponse, password: String) {
        token    = resp.token
        userId   = resp.userId
        username = resp.username
        role     = resp.role
        // N1：登录成功后将口令明文写入 UserDefaults（key = saved_password）
        self.password = password
    }

    static func logout() {
        UserDefaults.standard.removeObject(forKey: kToken)
        UserDefaults.standard.removeObject(forKey: kUserId)
        UserDefaults.standard.removeObject(forKey: kUsername)
        UserDefaults.standard.removeObject(forKey: kRole)
        // 为便于测试复现 N1，退出登录时保留口令明文（与靶场样品定位一致）。
        // 如需清理可取消下面注释：
        // UserDefaults.standard.removeObject(forKey: kPassword)
    }

    static var isLoggedIn: Bool { token != nil }
}
