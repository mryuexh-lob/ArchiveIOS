import SwiftUI

struct ArchiveDetailView: View {
    let taskId: Int
    @Environment(\.presentationMode) var presentationMode
    @State private var task: ArchiveTask?
    @State private var busy = false
    @State private var message: String?
    @State private var showError = false

    // 审核 / 归档弹出表单
    @State private var showReview = false
    @State private var showArchive = false
    @State private var reviewComment = ""
    @State private var archiveComment = ""
    @State private var archiveNo = ""
    @State private var archiveLocation = ""
    @State private var reviewAction = "pass"
    @State private var archiveAction = "pass"

    var body: some View {
        Group {
            if busy && task == nil {
                ProgressView()
            } else if let task = task {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(task.title ?? "工单").font(.title3).bold()
                            Spacer()
                            StatusBadge(status: task.status)
                        }
                        infoRow("工单号", task.taskNo)
                        infoRow("资料名称", task.docName)
                        infoRow("资料类型", task.docType)
                        HStack {
                            Text("密级").foregroundColor(.gray).frame(width: 80, alignment: .leading)
                            SecurityTag(level: task.securityLevel)
                            Spacer()
                        }.font(.subheadline)
                        infoRow("保管期限", task.retentionPeriod)
                        infoRow("归档部门", task.department)
                        infoRow("载体类型", task.carrierType)
                        infoRow("页数", task.pageCount.map { "\($0)" })
                        infoRow("描述", task.description)
                        infoRow("申请人", task.applicantName)
                        infoRow("审核员", task.reviewerName)
                        infoRow("归档员", task.archivistName)
                        infoRow("审核意见", task.reviewComment)
                        infoRow("归档意见", task.archiveComment)
                        infoRow("档号", task.archiveNo)
                        infoRow("存放位置", task.archiveLocation)
                        infoRow("创建时间", task.createdAt)
                        infoRow("审核时间", task.reviewedAt)
                        infoRow("归档时间", task.archivedAt)

                        Divider()
                        Text("操作").font(.headline)

                        // 审核通过/驳回：指定审核员 + 待审核
                        if task.status == "待审核", TokenManager.userId == task.reviewerId {
                            actionButton("审核通过", icon: "checkmark.circle") {
                                reviewAction = "pass"; showReview = true
                            }
                            actionButton("审核驳回", icon: "xmark.circle") {
                                reviewAction = "reject"; showReview = true
                            }
                        }
                        // 同意归档/驳回：ARCHIVIST + 待归档
                        if task.status == "待归档", TokenManager.role == "ARCHIVIST" {
                            actionButton("同意归档", icon: "archivebox") {
                                archiveAction = "pass"; showArchive = true
                            }
                            actionButton("归档驳回", icon: "xmark.circle") {
                                archiveAction = "reject"; showArchive = true
                            }
                        }
                        // 撤回：申请人 + 待审核
                        if task.status == "待审核", TokenManager.userId == task.applicantId {
                            Button {
                                Task { await doDelete() }
                            } label: {
                                Label("撤回工单", systemImage: "arrow.uturn.backward")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                }
            } else {
                Text("加载失败").foregroundColor(.gray)
            }
        }
        .navigationTitle("工单详情")
        .onAppear { Task { await load() } }
        .alert(isPresented: $showError) {
            Alert(title: Text("提示"), message: Text(message ?? ""),
                  dismissButton: .default(Text("确定")) { Task { await load() } })
        }
        .sheet(isPresented: $showReview)  { reviewSheet() }
        .sheet(isPresented: $showArchive) { archiveSheet() }
    }

    func load() async {
        busy = true
        do { task = try await APIClient.shared.archiveDetail(id: taskId) }
        catch { message = error.localizedDescription; showError = true }
        busy = false
    }

    func doDelete() async {
        busy = true
        do { try await APIClient.shared.deleteArchive(id: taskId); await MainActor.run { presentationMode.wrappedValue.dismiss() } }
        catch { message = error.localizedDescription; showError = true }
        busy = false
    }

    func submitReview() {
        // N3：客户端直接调用审核接口，不做角色拦截
        Task {
            busy = true
            do {
                try await APIClient.shared.reviewArchive(id: taskId, action: reviewAction, comment: reviewComment)
                await MainActor.run { showReview = false; reviewComment = "" }
                await load()
            } catch {
                await MainActor.run { message = error.localizedDescription; showError = true }
            }
            busy = false
        }
    }

    func submitArchive() {
        // N3：客户端直接调用归档接口，不做角色拦截
        Task {
            busy = true
            do {
                try await APIClient.shared.archiveArchive(id: taskId, action: archiveAction,
                                                          comment: archiveComment,
                                                          archiveNo: archiveNo,
                                                          archiveLocation: archiveLocation)
                await MainActor.run { showArchive = false; archiveComment = ""; archiveNo = ""; archiveLocation = "" }
                await load()
            } catch {
                await MainActor.run { message = error.localizedDescription; showError = true }
            }
            busy = false
        }
    }

    func reviewSheet() -> some View {
        NavigationView {
            Form {
                TextField("审核意见", text: $reviewComment)
            }
            .navigationTitle(reviewAction == "pass" ? "审核通过" : "审核驳回")
            .navigationBarItems(leading: Button("取消") { showReview = false },
                                trailing: Button("提交") { submitReview() })
        }
    }

    func archiveSheet() -> some View {
        NavigationView {
            Form {
                TextField("归档意见", text: $archiveComment)
                TextField("档号（如 DA-2026-0001）", text: $archiveNo)
                TextField("存放位置（如 A柜-3层-12号）", text: $archiveLocation)
            }
            .navigationTitle(archiveAction == "pass" ? "同意归档" : "归档驳回")
            .navigationBarItems(leading: Button("取消") { showArchive = false },
                                trailing: Button("提交") { submitArchive() })
        }
    }

    func infoRow(_ k: String, _ v: String?) -> some View {
        HStack(alignment: .top) {
            Text(k).foregroundColor(.gray).frame(width: 80, alignment: .leading)
            Text(v ?? "-").fixedSize(horizontal: false, vertical: true)
            Spacer()
        }.font(.subheadline)
    }

    func actionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}
