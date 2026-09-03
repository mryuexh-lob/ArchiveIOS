import SwiftUI

struct NewArchiveView: View {
    let onCreated: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var docName = ""
    @State private var docType = "合同文书"
    @State private var securityLevel = "内部"
    @State private var retentionPeriod = "10年"
    @State private var department = ""
    @State private var carrierType = "纸质"
    @State private var pageCount = ""
    @State private var description = ""
    @State private var reviewers: [Reviewer] = []
    @State private var reviewerId: Int?
    @State private var errorMsg: String?
    @State private var showError = false
    @State private var busy = false

    let docTypes = ["合同文书", "技术文档", "财务凭证", "人事档案", "项目资料", "声像资料"]
    let levels   = ["公开", "内部", "秘密", "机密"]
    let periods  = ["3年", "5年", "10年", "30年", "永久"]
    let carriers = ["纸质", "电子", "声像", "实物"]

    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("资料标题 *", text: $title)
                    TextField("资料名称", text: $docName)
                    Picker("资料类型", selection: $docType) { ForEach(docTypes, id: \.self) { Text($0) } }
                    Picker("密级", selection: $securityLevel) { ForEach(levels, id: \.self) { Text($0) } }
                    Picker("保管期限", selection: $retentionPeriod) { ForEach(periods, id: \.self) { Text($0) } }
                    TextField("归档部门", text: $department)
                    Picker("载体类型", selection: $carrierType) { ForEach(carriers, id: \.self) { Text($0) } }
                    TextField("页数", text: $pageCount).keyboardType(.numberPad)
                    TextField("资料描述", text: $description)
                }
                Section("指定审核员") {
                    Picker("审核员", selection: $reviewerId) {
                        Text("请选择").tag(Int?.none)
                        ForEach(reviewers) { rv in
                            Text(rv.realName ?? rv.username ?? "\(rv.id)").tag(Int?.some(rv.id))
                        }
                    }
                }
            }
            .navigationTitle("新建归档工单")
            .navigationBarItems(leading: Button("取消") { dismiss() },
                                trailing: Button("保存") { submit() })
            .onAppear { Task { await loadReviewers() } }
            .alert(isPresented: $showError) {
                Alert(title: Text("提示"), message: Text(errorMsg ?? ""),
                      dismissButton: .default(Text("确定")))
            }
        }
    }

    func loadReviewers() async {
        do { reviewers = try await APIClient.shared.reviewers() }
        catch { errorMsg = error.localizedDescription; showError = true }
    }

    func submit() {
        guard !title.isEmpty else { errorMsg = "资料标题不能为空"; showError = true; return }
        guard let rid = reviewerId else { errorMsg = "请指定审核员"; showError = true; return }
        busy = true
        Task {
            do {
                let pages = Int(pageCount) ?? 0
                let fields: [String: Any] = [
                    "title": title,
                    "docName": docName,
                    "docType": docType,
                    "securityLevel": securityLevel,
                    "retentionPeriod": retentionPeriod,
                    "department": department,
                    "carrierType": carrierType,
                    "pageCount": pages,
                    "description": description,
                    "reviewerId": rid
                ]
                try await APIClient.shared.createArchive(fields)
                await MainActor.run { dismiss(); onCreated() }
            } catch {
                await MainActor.run { errorMsg = error.localizedDescription; showError = true; busy = false }
            }
        }
    }
}
