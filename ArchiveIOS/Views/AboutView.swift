import SwiftUI

struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var latest: AppVersion?
    @State private var checking = false
    @State private var showUpdateInfo = false
    @State private var showPrivacy = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "tray.full.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.primaryColor)
                Text("资料归档助手").font(.title3).bold()
                Text("版本 \(appVersion())").foregroundColor(.gray)
                Text("服务器：\(TokenManager.serverURL.isEmpty ? "（未设置，请在服务器设置中填写）" : TokenManager.serverURL)")
                    .font(.footnote).foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("公司简介").font(.headline).foregroundColor(.primaryColor)
                        Text("本软件为电力行业资料归档管理系统的移动客户端，依据 EPRI 075-2021《移动应用软件安全技术要求及测试方法》设计，用于实验室移动应用安全测试的被测样品。系统覆盖归档工单发起、审核、归档入库等全流程，支持多角色协同与操作审计。")
                            .font(.subheadline).foregroundColor(.textPrimary)
                        Button { showPrivacy = true } label: {
                            Label("查看隐私政策", systemImage: "doc.text")
                        }
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 24)
                }

                Button { checkVersion() } label: {
                    if checking { ProgressView() } else { Text("检查更新") }
                }
                .frame(maxWidth: .infinity).padding(12)
                .background(Color.primaryColor).foregroundColor(.white).cornerRadius(10)
                .padding(.horizontal, 24)

                Spacer()
            }
            .padding(.top, 30)
            .navigationTitle("关于")
            .navigationBarItems(trailing: Button("关闭") { presentationMode.wrappedValue.dismiss() })
            .alert(isPresented: $showUpdateInfo) {
                Alert(title: Text("发现新版本"), message: Text(updateText()),
                      dismissButton: .default(Text("确定")))
            }
            .alert(isPresented: $showPrivacy) {
                Alert(title: Text("隐私政策"), message: Text("本应用为安全测试被测样品，在测试环境中收集并处理账号、口令、手机号、身份证号等个人信息，仅用于 EPRI 075-2021 相关安全测试验证，不会用于任何商业用途。"),
                      dismissButton: .default(Text("关闭")))
            }
        }
    }

    func appVersion() -> String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "V \(v) (build \(b))"
    }

    func checkVersion() {
        checking = true
        Task {
            do {
                latest = try await APIClient.shared.checkVersion()
                await MainActor.run { showUpdateInfo = true }
            } catch {
                latest = nil
            }
            await MainActor.run { checking = false }
        }
    }

    func updateText() -> String {
        guard let v = latest else { return "已是最新版本" }
        return "最新版本：\(v.versionName ?? "")\n更新内容：\(v.updateContent ?? "")"
    }
}
