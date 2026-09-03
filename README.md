# 资料归档助手 · iOS 客户端（ArchiveIOS，SwiftUI）

与安卓端（ArchiveApp）、后端（archive-backend）共用同一份《三方开发契约》。功能对齐：登录（可配服务器地址 + 隐私政策弹窗）、归档工单列表/新建/详情（按角色状态出现审核/归档/撤回）、我的（个人信息 + 修改密码 + 服务器设置 + 关于）。

> ⚠️ 当前 Windows 环境**无法编译 iOS 安装包**（苹果工具链 `xcodebuild` 只能在 macOS 运行）。
> 本目录提供的是**完整、可直接在 Mac 上编译出 `.ipa` 的 Xcode 工程源码**，配合 `codemagic.yaml` 即可自动出包。

---

## 一、目录结构

```
ArchiveSample/iOS/ArchiveIOS/
├── project.yml              # XcodeGen 配置，scheme/product 名 ArchiveIOS
├── codemagic.yaml           # 云构建：未签名 IPA（Sideloadly 侧载）
├── Info.plist              # 已允许 HTTP 明文（对应 S02）
├── ExportOptions.plist
├── README.md
└── ArchiveIOS/             # 源码子目录（注意：Codemagic 需 cd 进这一层）
    ├── App/                # @main 入口、AppState、墨青绿主题色
    ├── Models/             # 数据模型（字段名严格对齐契约）
    ├── Network/            # TokenManager + APIClient（URLSession）
    ├── Views/              # 各页面
    └── Assets.xcassets/
```

- bundleId：`com.epri.archive.ArchiveIOS`，scheme：`ArchiveIOS`，iOS 15+，Swift 5。
- 主题：墨青绿 `#2C7A6B` + 米白 `#F5F2EA`（区别于上一版蓝色系），色值在 `AppState.swift` 的 `Color` 扩展中统一引用。

---

## 二、本地构建（Mac）

前置：macOS + Xcode 15+、已装 [XcodeGen](https://github.com/yonaskolb/XcodeGen)（`brew install xcodegen`）。

```bash
cd ArchiveSample/iOS/ArchiveIOS     # 仓库根（含 codemagic.yaml / project.yml）
brew install xcodegen
cd ArchiveIOS                        # 进入源码子目录
xcodegen generate                    # 生成 ArchiveIOS.xcodeproj
open ArchiveIOS.xcodeproj
```

Xcode 中：选 `ArchiveIOS` target → Signing 选你的 Team（免费 Apple ID 即可）→ ⌘R 运行/出包。
服务器地址默认不写死，首次启动请在登录页或「我的-服务器设置」中填写实际后端地址（如 http://<服务器IP>:8082）。

---

## 三、云构建出未签名 IPA（Codemagic，免费侧载）

`codemagic.yaml` 已配成「未签名 IPA」路线：云 Mac 只编译、不碰任何苹果签名，
下载后在你 Windows 上用 [Sideloadly](https://sideloadly.app) + **免费 Apple ID** 侧载进手机。

> **踩坑提示（沿用上一版修正）**：源码放在仓库的 `ArchiveIOS/` 子目录下，
> 因此「生成工程 / 归档 / 打包」三个脚本步骤开头都 `cd ArchiveIOS`
> （否则会报 `No project spec found in .../project.yml`）。artifacts 路径也带子目录前缀
> `ArchiveIOS/build/ipa/ArchiveIOS.ipa`。

步骤：
1. 把本目录推到 GitHub（仓库根直接是 `codemagic.yaml`）。
2. Codemagic → Add application → 选该仓库 → Start new build（无需任何 Apple 凭据）。
3. Artifacts 下载 `ArchiveIOS.ipa`，Sideloadly 用免费 Apple ID 重签安装；手机 设置→通用→VPN与设备管理 信任开发者。

---

## 四、与契约一致的预埋缺陷（便于测试）

- **N1 敏感数据本地明文存储**：`LoginView` 登录成功后调用 `TokenManager.saveLogin(_:password:)`，
  将口令明文写入 `UserDefaults`，key = `saved_password`（token/userId 同样明文）。
  验证：Xcode Devices 导出 App 容器看 `plist`，或「我的」页回显。位置 `Network/TokenManager.swift` 的 `saveLogin`。
- **N3 垂直越权**：`ArchiveDetailView` 调用 `/api/archives/{id}/review`、`/archive` 时客户端不做角色拦截
  （UI 按钮仍按角色显示）。可用任意登录用户直接 POST 这两个接口验证。
- **N5 敏感个人信息展示未脱敏**：「我的」页手机号、身份证号**完整明文**展示（不打掩码）。位置 `Views/MineView.swift`。
- **S02 HTTP 明文**：`Info.plist` 已开 `NSAllowsArbitraryLoads`，Burp 可直接抓到明文口令。

符合项：C1 登录失败模糊提示、C3 列表归属隔离、C5 未带 token 返回 401、C6 隐私政策首次弹窗（不同意 `exit(0)`）。

---

## 五、注意事项

- AppIcon 为占位空目录，编译有警告但不影响出包。
- 最低支持 iOS 15.0；服务器含 IP 时需手机与后端同局域网。
- 退出登录时**保留** `saved_password` 明文（靶场复现需要），如需清理由 `TokenManager.logout()` 内注释切换。
