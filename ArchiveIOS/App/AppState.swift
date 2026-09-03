import SwiftUI
import Combine

/// 全局登录状态（驱动登录页与主界面的切换）。
class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = TokenManager.isLoggedIn

    func login()  { isLoggedIn = true }
    func logout() { TokenManager.logout(); isLoggedIn = false }
}

extension Color {
    /// 从十六进制构造颜色，如 Color(hex: 0x2C7A6B)。
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8)  & 0xFF) / 255.0,
            blue:  Double(hex        & 0xFF) / 255.0,
            opacity: alpha
        )
    }

    // MARK: - 墨青绿 + 米白 主题（档案卷宗质感，区别于上一版蓝色系）
    static let primaryColor  = Color(hex: 0x2C7A6B) // 墨青绿，主色
    static let primaryDark   = Color(hex: 0x1F5A4F) // 深墨绿（按压态）
    static let primaryLight  = Color(hex: 0x6FA89A) // 浅青（次要按钮/图标底）
    static let accentGold    = Color(hex: 0xC89B3C) // 档案黄铜金（密级标签/档号）
    static let appBackground = Color(hex: 0xF5F2EA) // 米白/羊皮纸（页面底色）
    static let appSurface    = Color(hex: 0xFFFFFF) // 卡片白
    static let textPrimary   = Color(hex: 0x22312C) // 正文深墨
    static let textSecondary = Color(hex: 0x6B7C75) // 次要文字
    static let appDivider    = Color(hex: 0xDCD8CC) // 分割线
    static let successGreen  = Color(hex: 0x4A8B5C) // 已归档/通过
    static let warningGold   = Color(hex: 0xC89B3C) // 待审核
    static let dangerRed     = Color(hex: 0xB5483C) // 驳回

    /// 工单状态色标：待审核=金 / 待归档=青 / 已归档=绿 / 已驳回=红
    static func statusColor(_ status: String?) -> Color {
        switch status {
        case "待审核": return warningGold
        case "待归档": return primaryColor
        case "已归档": return successGreen
        case "已驳回": return dangerRed
        default:       return textSecondary
        }
    }
}
