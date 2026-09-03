import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ArchiveListView()
                .tabItem { Label("工单", systemImage: "tray.full") }

            MineView()
                .tabItem { Label("我的", systemImage: "person") }
        }
        .accentColor(.primaryColor)
    }
}
