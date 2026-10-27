import AppKit

/// 可选：Word 文档转 PDF 交给 Microsoft Word 自己导出，排版和在 Word 里“导出 › PDF”一致。
/// 默认关闭（设置里打开）：比 LibreOffice 慢，而且 Word 可能借助微软的在线服务生成 PDF。
/// Word 是沙盒应用，只能写自己的容器目录，所以先导出到它的临时目录，再由 Peel 挪到原文件旁边。
enum WordExporter {
    static let bundleID = "com.microsoft.Word"
    static let sources: Set<String> = ["doc", "docx", "rtf", "odt"]

    static var isInstalled: Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) != nil
    }

    /// 设置里打开了、装了 Word、而且是 Word 能打开的文档
    static func shouldUse(_ src: URL, target: String) -> Bool {
        target == "pdf" && Settings.useWordForPDF && isInstalled && sources.contains(FileKind.normalizedExt(src))
    }

    /// 加密的 docx 实际上是 OLE 复合文件而不是 zip；交给 Word 会弹出密码框卡住
    private static func isEncryptedOOXML(_ src: URL) -> Bool {
        guard FileKind.normalizedExt(src) == "docx",
              let h = try? FileHandle(forReadingFrom: src) else { return false }
        defer { try? h.close() }
        return h.readData(ofLength: 4) == Data([0xD0, 0xCF, 0x11, 0xE0])
    }

    static func exportPDF(_ src: URL) throws -> URL {
        if isEncryptedOOXML(src) {
            throw PeelError("「\(src.lastPathComponent)」有密码保护，请先在 Word 里去掉密码",
                            "“\(src.lastPathComponent)” is password-protected")
        }
        let wasRunning = !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
        let script = """
        on run argv
            set srcPath to item 1 of argv
            set outName to item 2 of argv
            set quitAfter to (item 3 of argv) is "quit"
            set fileName to item 4 of argv
            -- 文件引用在 tell 外面生成：系统会把读取权限一起交给沙盒里的 Word
            set srcFile to POSIX file srcPath
            tell application "Microsoft Word"
                -- 用户已经打开了这个文件：导出后不要关掉
                set openNames to name of every document
                if openNames is missing value then set openNames to {}
                set alreadyOpen to openNames contains fileName
                open srcFile
                -- Word 打开文件是异步的，等文档真正出现
                set d to missing value
                repeat 120 times
                    try
                        set d to document fileName
                        exit repeat
                    end try
                    delay 0.25
                end repeat
                if d is missing value then
                    -- 打不开时，把我们启动的 Word 关掉，免得它卡在异常状态影响下一次
                    if quitAfter and (count of documents) is 0 then quit saving no
                    error "Word could not open the file" number 1001
                end if
                set outPath to (POSIX path of (path to temporary items)) & outName
                save as d file name outPath file format format PDF
                if not alreadyOpen then close d saving no
                if quitAfter then
                    -- 关闭也是异步的：等文档真正关掉再退出 Word
                    repeat 20 times
                        if (count of documents) is 0 then exit repeat
                        delay 0.25
                    end repeat
                    if (count of documents) is 0 then quit saving no
                end if
                return outPath
            end tell
        end run
        """
        let output: String
        do {
            output = try Shell.run("/usr/bin/osascript",
                                   ["-e", script, src.path, "peel-\(UUID().uuidString).pdf",
                                    wasRunning ? "keep" : "quit", src.lastPathComponent],
                                   timeout: 120)
        } catch let e as ToolFailure where e.output.contains("-1743") {
            throw PeelError("请在“系统设置 › 隐私与安全性 › 自动化”里允许 Peel 控制 Microsoft Word",
                            "Allow Peel to control Microsoft Word in System Settings › Privacy & Security › Automation")
        }
        let tmp = URL(fileURLWithPath: output.trimmingCharacters(in: .whitespacesAndNewlines))
        guard FileManager.default.fileExists(atPath: tmp.path) else {
            throw PeelError("Word 导出失败", "Word export failed")
        }
        return try Output.place(tmp, at: Output.sibling(of: src, ext: "pdf"))
    }
}
