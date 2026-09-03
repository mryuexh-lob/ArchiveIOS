import SwiftUI

// MARK: - 密级标签（金标）
struct SecurityTag: View {
    let level: String?
    var body: some View {
        Text(level ?? "")
            .font(.caption2)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Color.accentGold.opacity(0.18))
            .foregroundColor(Color.accentGold)
            .cornerRadius(6)
            .opacity((level ?? "").isEmpty ? 0 : 1)
    }
}

// MARK: - 状态色标
struct StatusBadge: View {
    let status: String?
    var body: some View {
        Text(status ?? "")
            .font(.caption2)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Color.statusColor(status).opacity(0.15))
            .foregroundColor(Color.statusColor(status))
            .cornerRadius(6)
            .opacity((status ?? "").isEmpty ? 0 : 1)
    }
}

// MARK: - 工单列表
struct ArchiveListView: View {
    @State private var tasks: [ArchiveTask] = []
    @State private var statusFilter = ""
    @State private var docType = ""
    @State private var keyword = ""
    @State private var busy = false
    @State private var errorMsg: String?
    @State private var showNew = false
    @State private var showFilter = false

    let statuses = ["", "待审核", "待归档", "已归档", "已驳回"]
    let types = ["", "合同文书", "技术文档", "财务凭证", "人事档案", "项目资料", "声像资料"]

    var body: some View {
        NavigationView {
            VStack {
                // 状态筛选 Tab
                Picker("状态", selection: $statusFilter) {
                    ForEach(statuses, id: \.self) { Text($0.isEmpty ? "全部" : $0) }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 12)

                HStack {
                    TextField("搜索工单号/标题", text: $keyword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("筛选") { showFilter.toggle() }
                }
                .padding(.horizontal, 12).padding(.top, 4)

                if showFilter {
                    Picker("资料类型", selection: $docType) {
                        ForEach(types, id: \.self) { Text($0.isEmpty ? "全部" : $0) }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal, 12)
                }

                if busy && tasks.isEmpty {
                    ProgressView()
                } else if tasks.isEmpty {
                    Spacer()
                    Text("暂无归档工单").foregroundColor(.gray)
                    Spacer()
                } else {
                    List(tasks) { task in
                        NavigationLink(destination: ArchiveDetailView(taskId: task.id)) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(task.title ?? "未命名").font(.headline)
                                    Spacer()
                                    StatusBadge(status: task.status)
                                }
                                Text(task.taskNo ?? "").font(.caption).foregroundColor(.gray)
                                HStack {
                                    SecurityTag(level: task.securityLevel)
                                    Text(task.docType ?? "").font(.caption).foregroundColor(.gray)
                                    Spacer()
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("归档工单")
            .navigationBarItems(trailing: newButton)
            .onChange(of: statusFilter) { _ in Task { await load() } }
            .onChange(of: docType) { _ in Task { await load() } }
            .onSubmit(of: .text) { Task { await load() } }
            .onAppear { Task { await load() } }
            .sheet(isPresented: $showNew) {
                NewArchiveView(onCreated: { Task { await load() } })
            }
        }
        .navigationViewStyle(.stack)
    }

    // 新建按钮仅申请人可见
    @ViewBuilder
    var newButton: some View {
        if TokenManager.role == "APPLICANT" {
            Button(action: { showNew = true }) { Image(systemName: "plus") }
        }
    }

    func load() async {
        busy = true; errorMsg = nil
        do {
            tasks = try await APIClient.shared.archives(status: statusFilter, docType: docType, keyword: keyword)
        } catch {
            errorMsg = error.localizedDescription
        }
        busy = false
    }
}
