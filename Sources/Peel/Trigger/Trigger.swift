import AppKit

/// 长按达到时长后的处理：确认是在 Finder 文件上，然后弹出轮盘。
/// 鼠标还按着时不向 Finder 发 Apple Event（会打断它的拖动跟踪，导致拖不动文件），
/// 只用辅助功能读出鼠标下的文件先填好轮盘；一拖动，就以拖进来的文件为准。
enum Trigger {
    static func fire(at point: NSPoint) {
        guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == FinderBridge.finderID else { return }
        let wheel = WheelController.shared
        guard !wheel.isVisible, !SnapController.shared.isCapturing else { return }

        // 能判断时，排除标题栏 / 边栏 / 空白处
        let over = FinderBridge.isOverFinderItem(point)
        Log.write("long press: AX trusted=\(AXIsProcessTrusted()) overItem=\(String(describing: over))")
        if over == false { return }

        if let file = FinderBridge.fileUnderCursor(point) {
            Log.write("file under cursor: \(file.path)")
            wheel.show(at: point, files: [file], mode: .drag)
            return
        }

        // 没有辅助功能权限，判断不了按的是什么：
        // 先排除窗口顶部的工具栏，再问 Finder 选中了什么——按在文件上时它已被选中，
        // 按在空白处时选中会被清空。确实有文件才弹出轮盘，否则什么都不做。
        if FinderBridge.isOnFinderToolbar(point) {
            Log.write("long press on Finder toolbar, ignored")
            return
        }
        askFinder(at: point, attempt: 1)
    }

    /// 鼠标按住一动不动时，Finder 还在处理这次按下，可能迟迟不回应；超时就再问（最多 3 次）
    private static func askFinder(at point: NSPoint, attempt: Int) {
        FinderBridge.fetchSelection(timeout: 2) { result in
            Log.write("selection fallback #\(attempt): \(result)")
            let wheel = WheelController.shared
            guard !wheel.isVisible else { return }
            switch result {
            case .success(let urls) where !urls.isEmpty:
                // 等回答的时候用户可能已经松手：那就用点选模式，轮盘留着点扇区
                let stillPressed = NSEvent.pressedMouseButtons & 1 != 0
                wheel.show(at: point, files: urls, mode: stillPressed ? .drag : .click)
            case .failure(.timeout) where attempt < 3:
                askFinder(at: point, attempt: attempt + 1)
            default:
                break   // 没选中文件（按在空白处）或问不到：不弹出
            }
        }
    }
}
