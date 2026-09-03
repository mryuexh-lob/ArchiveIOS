import Foundation

// MARK: - 登录响应（字段名严格对齐契约 /api/auth/login）
struct LoginResponse: Codable {
    let token: String
    let userId: Int?
    let username: String?
    let role: String?
    let realName: String?
    let phone: String?
    let idCard: String?
    let department: String?
    let menus: [MenuInfo]?
}

struct MenuInfo: Codable {
    let name: String?
    let path: String?
    let icon: String?
    let parentId: Int?
}

// MARK: - 当前用户信息（/api/auth/me）
struct UserInfo: Codable {
    let userId: Int?
    let username: String?
    let role: String?
    let realName: String?
    let phone: String?
    let idCard: String?
    let department: String?
    let email: String?
    let menus: [MenuInfo]?
}

// MARK: - 归档工单（ArchiveTask，字段名驼峰对齐契约第四节）
struct ArchiveTask: Identifiable, Codable {
    let id: Int
    let taskNo: String?
    let title: String?
    let docName: String?
    let docType: String?
    let securityLevel: String?
    let retentionPeriod: String?
    let department: String?
    let carrierType: String?
    let pageCount: Int?
    let description: String?
    let applicantId: Int?
    let applicantName: String?
    let reviewerId: Int?
    let reviewerName: String?
    let archivistId: Int?
    let archivistName: String?
    let status: String?
    let reviewComment: String?
    let archiveComment: String?
    let archiveNo: String?
    let archiveLocation: String?
    let createdAt: String?
    let reviewedAt: String?
    let archivedAt: String?
}

// MARK: - 审核员 / 归档员（/api/archives/reviewers、archivists）
struct Reviewer: Identifiable, Codable {
    let id: Int
    let username: String?
    let realName: String?
    let role: String?
}

// MARK: - 审核/归档操作返回（带新 status）
struct StatusResponse: Codable {
    let message: String?
    let status: String?
}

// MARK: - App 版本（/api/version）
struct AppVersion: Codable {
    let versionName: String?
    let versionCode: Int?
    let updateContent: String?
    let forceUpdate: Bool?
}
