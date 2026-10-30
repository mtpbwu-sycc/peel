import AppKit
import SwiftUI

/// 设置窗口：长按、快捷键、语言、权限。菜单栏菜单里只留常用操作
final class SettingsWindow: NSObject, NSWindowDelegate {
    private static var current: SettingsWindow?
    private let window: NSWindow

    static func open() {
        if let current {
            NSApp.activate(ignoringOtherApps: true)
            current.window.makeKeyAndOrderFront(nil)
            return
        }
        let holder = SettingsWindow()
        current = holder
        NSApp.activate(ignoringOtherApps: true)
        holder.window.makeKeyAndOrderFront(nil)
        // 不要默认聚焦到某个按钮（会把列表滚到底部）
        holder.window.makeFirstResponder(nil)
    }

    private override init() {
        window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        super.init()
        window.title = t("Peel 设置", "Peel Settings")
        window.isReleasedWhenClosed = false
        window.delegate = self
        let size = NSSize(width: 500, height: 700)
        window.contentView = NSHostingView(rootView: SettingsView().frame(width: size.width, height: size.height))
        window.setContentSize(size)
        window.center()
        // 从菜单栏切换语言后，标题跟着变
        langObserver = NotificationCenter.default.addObserver(forName: Settings.langChanged, object: nil, queue: .main) {
            [weak window] _ in window?.title = t("Peel 设置", "Peel Settings")
        }
    }

    private var langObserver: NSObjectProtocol?

    func windowWillClose(_ notification: Notification) {
        if let langObserver { NotificationCenter.default.removeObserver(langObserver) }
        if SettingsWindow.current === self { SettingsWindow.current = nil }
    }
}

private struct SettingsView: View {
    /// 语言在菜单栏里切换；切换后整页重绘
    @State private var lang = Settings.lang
    @State private var longPress = Settings.longPressEnabled
    @State private var hold = Settings.holdDuration
    @State private var dwell = Settings.dwellDuration
    @State private var snapKey = Shortcut.presets.firstIndex(of: Settings.snapShortcut) ?? 0
    @State private var wheelKey = Shortcut.wheelPresets.firstIndex(of: Settings.wheelShortcut) ?? 0
    @State private var mirror = Settings.useChinaMirror
    @State private var wordPDF = Settings.useWordForPDF
    @State private var theme = Settings.wheelTheme
    @State private var followsDark = Settings.wheelFollowsDark
    @State private var loginItem = LoginItem.isEnabled
    @State private var updates = Settings.checkForUpdates

    var body: some View {
        ScrollViewReader { proxy in
        Form {
            Section(t("轮盘外观", "Wheel style")) {
                HStack(spacing: 10) {
                    ForEach(WheelTheme.allCases) { th in
                        ThemeCard(theme: th, selected: theme == th) {
                            theme = th
                            Settings.wheelTheme = th
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                Toggle(t("系统深色模式时用深色轮盘", "Use a dark wheel in Dark Mode"), isOn: $followsDark)
                    .onChange(of: followsDark) { Settings.wheelFollowsDark = $0 }
            }
            .id("top")

            Section(t("长按", "Long-press")) {
                Toggle(t("在访达里长按文件弹出轮盘", "Hold a file in Finder to open the wheel"), isOn: $longPress)
                    .onChange(of: longPress) { Settings.longPressEnabled = $0 }
                slider(t("长按时长", "Hold duration"), value: $hold, range: 0.5...3.0,
                       defaultValue: Settings.defaultHold) { Settings.holdDuration = $0 }
                    .disabled(!longPress)
                slider(t("悬停展开等待", "Hover-to-open delay"), value: $dwell, range: 0.3...1.5,
                       defaultValue: Settings.defaultDwell) { Settings.dwellDuration = $0 }
            }

            Section {
                Picker(t("截图", "Screenshot"), selection: $snapKey) {
                    ForEach(Shortcut.presets.indices, id: \.self) { Text(Shortcut.presets[$0].label).tag($0) }
                }
                .onChange(of: snapKey) { i in
                    let sc = Shortcut.presets[i]
                    Settings.snapShortcut = sc
                    HotKey.shared.register(.snap, sc) { SnapController.shared.start() }
                }
                Picker(t("打开轮盘", "Open wheel"), selection: $wheelKey) {
                    ForEach(Shortcut.wheelPresets.indices, id: \.self) { Text(Shortcut.wheelPresets[$0].label).tag($0) }
                }
                .onChange(of: wheelKey) { i in
                    let sc = Shortcut.wheelPresets[i]
                    Settings.wheelShortcut = sc
                    HotKey.shared.register(.wheel, sc) { WheelEntry.openForFinderSelection() }
                }
            } header: {
                Text(t("快捷键", "Shortcuts"))
            } footer: {
                Text(t("打开轮盘：先在访达里选中文件再按。也可以右键文件 › 服务 › 用 Peel 处理。",
                       "Open wheel: select files in Finder first. Or right-click › Services › Process with Peel."))
                    .font(.callout).foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading).frame(maxWidth: .infinity, alignment: .leading)
            }

            Section {
                Toggle(t("用 Microsoft Word 导出", "Export with Microsoft Word"), isOn: $wordPDF)
                    .onChange(of: wordPDF) { Settings.useWordForPDF = $0 }
                    .disabled(!WordExporter.isInstalled)
            } header: {
                Text(t("Word 转 PDF", "Word → PDF"))
            } footer: {
                Text(WordExporter.isInstalled
                     ? t("排版和在 Word 里「导出 › PDF」一致，还原度最高；但每份要 10 秒左右，而且 Word 可能借助微软的在线服务生成 PDF（文档会上传）。关闭时用 LibreOffice：快、完全离线。",
                         "Same layout as File › Export › PDF in Word. Slower (about 10 s per file), and Word may use Microsoft's online service to make the PDF (the document is uploaded). When off, LibreOffice is used: fast and fully offline.")
                     : t("需要安装 Microsoft Word。现在用 LibreOffice：快、完全离线。",
                         "Requires Microsoft Word. Currently using LibreOffice: fast and fully offline."))
                    .font(.callout).foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading).frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section(t("通用", "General")) {
                Toggle(t("开机时自动启动 Peel", "Open Peel at login"), isOn: $loginItem)
                    .onChange(of: loginItem) { on in
                        LoginItem.set(on)
                        loginItem = LoginItem.isEnabled
                    }
                Toggle(t("自动检查更新", "Check for updates automatically"), isOn: $updates)
                    .onChange(of: updates) { on in
                        Settings.checkForUpdates = on
                        if on { UpdateChecker.start() }
                    }
                HStack {
                    Text(t("当前版本 ", "Version ") + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(t("现在检查更新", "Check Now")) { UpdateChecker.check(userInitiated: true) }
                }
                Toggle(t("安装组件时使用国内镜像", "Use China mirrors when installing components"), isOn: $mirror)
                    .onChange(of: mirror) { Settings.useChinaMirror = $0 }
            }

            Section(t("权限与入口", "Permissions")) {
                HStack {
                    Button(t("检查访达访问权限", "Check Finder access")) {
                        FinderBridge.fetchSelection(timeout: 60) { result in
                            if case .failure(.notAuthorized) = result { FinderBridge.openAutomationSettings() }
                            else { HUD.shared.show(t("访达访问正常", "Finder access OK")) }
                        }
                    }
                    Button(t("右键服务设置…", "Services settings…")) {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension")!)
                    }
                }
            }
        }
        .formStyle(.grouped)
        // 打开时停在最上面（否则会自动滚到某个按钮那里）
        .onAppear {
            for delay in [0.0, 0.15, 0.4] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { proxy.scrollTo("top", anchor: .top) }
            }
        }
        }
        .id(lang)
        .onReceive(NotificationCenter.default.publisher(for: Settings.langChanged)) { _ in lang = Settings.lang }
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>,
                        defaultValue: Double, save: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: t("%.1f 秒", "%.1fs"), value.wrappedValue)).monospacedDigit().foregroundStyle(.secondary)
                Button(t("默认", "Default")) { value.wrappedValue = defaultValue }
                    .controlSize(.small)
                    .disabled(abs(value.wrappedValue - defaultValue) < 0.05)
            }
            Slider(value: value, in: range, step: 0.1).labelsHidden()
        }
        .onChange(of: value.wrappedValue) { save($0) }
    }
}

/// 外观选择卡片：用离屏渲染画一个小轮盘（照片的第一层，“编辑”扇区高亮）
private struct ThemeCard: View {
    let theme: WheelTheme
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Group {
                    if let img = Self.thumbnail(theme) {
                        Image(nsImage: img).resizable()
                    } else {
                        Color.secondary.opacity(0.1)
                    }
                }
                .frame(width: 92, height: 92)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(selected ? PeelColors.ring : Color.secondary.opacity(0.2), lineWidth: selected ? 2.5 : 1))
                Text(theme.title.text)
                    .font(.system(size: 12, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? Color.primary : Color.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private static var cache: [WheelTheme: NSImage] = [:]

    @MainActor
    static func thumbnail(_ theme: WheelTheme) -> NSImage? {
        if let img = cache[theme] { return img }
        let c = WheelController()
        c.debugDemo(files: [URL(fileURLWithPath: "/Peel preview/Photo.jpg")], hover: 2, dwell: 0)
        // 离屏渲染时毛玻璃改用材质画，否则模糊的是窗口后面的桌面
        let was = WheelView.offscreen
        WheelView.offscreen = true
        defer { WheelView.offscreen = was }
        let view = ZStack {
            LinearGradient(colors: [Color(red: 0.99, green: 0.62, blue: 0.33), Color(red: 0.86, green: 0.33, blue: 0.55)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            WheelView(controller: c, theme: theme)
        }
        .frame(width: WheelMetrics.size, height: WheelMetrics.size)
        .environment(\.colorScheme, .light)
        let r = ImageRenderer(content: view)
        r.scale = 0.5
        let img = r.nsImage
        cache[theme] = img
        return img
    }
}
