import AppKit
import ServiceManagement

/// 检查 GitHub 上有没有新版本：启动时查一次，之后每天一次。只读取公开的版本号，不发送任何个人信息。
enum UpdateChecker {
    static let repo = "mtpbwu-sycc/peel"
    static var releasesPage: URL { URL(string: "https://github.com/\(repo)/releases/latest")! }

    /// 有新版本时的版本号（菜单里显示“有新版本”）
    private(set) static var available: String?
    private static var timer: Timer?

    static func start() {
        guard Settings.checkForUpdates else { return }
        check()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 24 * 3600, repeats: true) { _ in check() }
    }

    static func check(userInitiated: Bool = false) {
        // 不用 GitHub API（按网络出口限流，共用代理时很容易用完）：
        // 直接请求 releases/latest 网页，它会跳转到 …/releases/tag/v1.2.3，从跳转后的地址取版本号
        var req = URLRequest(url: releasesPage)
        req.httpMethod = "HEAD"
        req.timeoutInterval = 15
        URLSession.shared.dataTask(with: req) { _, response, error in
            let last = response?.url?.lastPathComponent
            let tag = (last?.hasPrefix("v") ?? false) ? last : nil
            DispatchQueue.main.async {
                guard let tag else {
                    Log.write("update check failed: \(error?.localizedDescription ?? "unexpected url \(response?.url?.absoluteString ?? "-")")")
                    if userInitiated { HUD.shared.show(t("检查更新失败，请稍后再试", "Couldn't check for updates"), symbol: "wifi.exclamationmark") }
                    return
                }
                let latest = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
                let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
                if isNewer(latest, than: current) {
                    let first = available != latest
                    available = latest
                    if first || userInitiated {
                        HUD.shared.show(t("Peel \(latest) 已发布，点菜单栏图标查看", "Peel \(latest) is available — see the menu bar icon"),
                                        symbol: "arrow.down.circle.fill", duration: 4)
                    }
                } else {
                    available = nil
                    if userInitiated { HUD.shared.show(t("已经是最新版本 \(current)", "You're up to date (\(current))")) }
                }
            }
        }.resume()
    }

    /// 按数字逐段比较版本号：0.10.0 比 0.9.3 新
    static func isNewer(_ a: String, than b: String) -> Bool {
        let x = a.split(separator: ".").map { Int($0) ?? 0 }, y = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(x.count, y.count) {
            let p = i < x.count ? x[i] : 0, q = i < y.count ? y[i] : 0
            if p != q { return p > q }
        }
        return false
    }
}

/// 开机自动启动（系统“登录项”）
enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    static func set(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            Log.write("login item \(on ? "register" : "unregister") failed: \(error)")
        }
    }

    /// 第一次运行时默认打开
    static func applyDefaultOnce() {
        guard !UserDefaults.standard.bool(forKey: "didSetLoginItem") else { return }
        UserDefaults.standard.set(true, forKey: "didSetLoginItem")
        set(true)
    }
}
