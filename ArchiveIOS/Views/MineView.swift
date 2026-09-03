import SwiftUI

struct MineView: View {
    @EnvironmentObject var appState: AppState
    @State private var user: UserInfo?
    @State private var showChangePwd = false
    @State private var showAbout = false
    @State private var showServer = false
    @State private var errorMsg: String?
    @State private var showError = false

    var body: some View {
        NavigationView {
            VStack {
                VStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.primaryColor)
                    Text(user?.realName ?? user?.username ?? "未登录")
                        .font(.title3).bold()
                    Text(roleName(user?.role)).font(.footnote).foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color.primaryColor.opacity(0.08))

                List {
                    // 个人信息（N5：手机号/身份证号完整明文展示，不做掩码）
                    Section("个人信息") {
                        infoRow("账号", user?.username)
                        infoRow("姓名", user?.realName)
                        infoRow("角色", roleName(user?.role))
                        infoRow("部门", user?.department)
                        infoRow("手机号", user?.phone)     // N5 明文
                        infoRow("身份证号", user?.idCard)  // N5 明文（完整 18 位）
                    }
                    Section {
                        Button { showChangePwd = true } label: {
                            Label("修改密码", systemImage: "lock.rotation")
                        }
                        Button { showServer = true } label: {
                            Label("服务器设置", systemImage: "server.rack")
                        }
                        Button { showAbout = true } label: {
                            Label("关于", systemImage: "info.circle")
                        }
                    }
                    Section {
                        Button(role: .destructive) { appState.logout() } label: {
                            Label("退出登录", systemImage: "arrow.backward.square")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("我的")
            .navigationBarHidden(true)
            .onAppear { Task { await load() } }
            .sheet(isPresented: $showChangePwd) { ChangePasswordView() }
            .sheet(isPresented: $showAbout)    { AboutView() }
            .sheet(isPresented: $showServer)   { ServerSettingsSheet() }
            .alert(isPresented: $showError) {
                Alert(title: Text("错误"), message: Text(errorMsg ?? ""),
                      dismissButton: .default(Text("确定")))
            }
        }
        .navigationViewStyle(.stack)
    }

    func load() async {
        do { user = try await APIClient.shared.me() }
        catch { errorMsg = error.localizedDescription; showError = true }
    }

    func roleName(_ r: String?) -> String {
        switch r {
        case "ADMIN":     return "档案管理主管"
        case "APPLICANT": return "归档申请人"
        case "REVIEWER":  return "资料审核员"
        case "ARCHIVIST": return "档案归档员"
        case "AUDITOR":   return "档案审计员"
        default:          return r ?? "用户"
        }
    }

    func infoRow(_ k: String, _ v: String?) -> some View {
        HStack(alignment: .top) {
            Text(k).foregroundColor(.gray).frame(width: 80, alignment: .leading)
            Text(v ?? "-").fixedSize(horizontal: false, vertical: true)
            Spacer()
        }.font(.subheadline)
    }
}
