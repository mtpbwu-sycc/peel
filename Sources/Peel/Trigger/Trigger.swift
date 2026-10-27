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

        let file = FinderBridge.fileUnderCursor(point)
        Log.write("file under cursor: \(file?.path ?? "nil")")
        wheel.show(at: point, files: file.map { [$0] } ?? [], mode: .drag)

        // 辅助功能读不出来（比如还没授权）：向 Finder 要选中的文件来填轮盘。
        // 轮盘自己跟踪鼠标，不依赖 Finder 的拖动，所以这时发请求也没关系
        if file == nil { fillFromSelection(attempt: 1) }
    }

    /// 鼠标按住一动不动时，Finder 还在处理这次按下，可能迟迟不回应；
    /// 超时后只要轮盘还开着、还是空的，就再问一次（最多 4 次）
    private static func fillFromSelection(attempt: Int) {
        let wheel = WheelController.shared
        FinderBridge.fetchSelection(timeout: 2) { result in
            Log.write("selection fallback #\(attempt): \(result)")
            if case .success(let urls) = result, !urls.isEmpty {
                wheel.fillIfEmpty(urls)
            } else if attempt < 4, wheel.isVisible, wheel.files.isEmpty {
                fillFromSelection(attempt: attempt + 1)
            }
        }
    }
}
