import AppKit
import SwiftUI

/// 轮盘外观。只改样子，扇区、交互、动画都一样
enum WheelTheme: String, CaseIterable, Identifiable {
    case classic, simple, cartoon, glass
    var id: String { rawValue }

    var title: LText {
        switch self {
        case .classic: return LText("经典", "Classic")
        case .simple: return LText("磨砂", "Frosted")
        case .cartoon: return LText("卡通", "Cartoon")
        case .glass: return LText("玻璃", "Glass")
        }
    }

    /// 当前用的外观（深色模式下若开了“跟随系统”则用深色版本）
    static func style(dark: Bool) -> WheelStyle {
        Settings.wheelTheme.style(dark: dark && Settings.wheelFollowsDark)
    }

    func style(dark: Bool) -> WheelStyle {
        let orange = PeelColors.hot
        let darkFill = LinearGradient(colors: [Color(white: 0.27), Color(white: 0.18)], startPoint: .topLeading, endPoint: .bottomTrailing)
        let brown = Color(red: 0.29, green: 0.16, blue: 0.08)
        let inkLight = Color(white: 0.94)

        switch self {
        case .classic:
            return WheelStyle(
                base: .bevelGlass,
                sectorFill: dark ? AnyShapeStyle(darkFill) : AnyShapeStyle(PeelColors.creamLit),
                hotFill: AnyShapeStyle(orange),
                ink: dark ? inkLight : PeelColors.ink,
                sectorShadow: dark ? .black.opacity(0.35) : Color(red: 0.5, green: 0.28, blue: 0.12).opacity(0.18),
                centerFill: dark ? AnyShapeStyle(Color(white: 0.22)) : AnyShapeStyle(LinearGradient(
                    colors: [Color.white.opacity(0.97), Color(red: 1, green: 0.95, blue: 0.9).opacity(0.92)],
                    startPoint: .top, endPoint: .bottom)))
        case .simple:
            // 磨砂玻璃：系统菜单材质的底，扇区是更不透明的雾白面板，带一层细颗粒；悬停那一块变成橙色
            return WheelStyle(
                base: .plainGlass,
                sectorFill: AnyShapeStyle(LinearGradient(colors: [Color.white, Color.white.opacity(0.82)],
                                                         startPoint: .top, endPoint: .bottom)),
                hotFill: AnyShapeStyle(Color(red: 1.0, green: 0.5, blue: 0.12)),
                ink: dark ? Color.white.opacity(0.9) : Color.black.opacity(0.8),
                sectorOpacity: dark ? 0.14 : 0.7,
                grain: dark ? 0.025 : 0.045,
                hoverGlow: 0, pop: 0,
                centerFill: AnyShapeStyle(dark ? Color.white.opacity(0.12) : Color.white.opacity(0.75)),
                centerOutline: .clear,
                ringTrack: dark ? Color.white.opacity(0.15) : Color.black.opacity(0.08))
        case .cartoon:
            // 粗描边 + 平涂 + 硬投影，和宣传动画一致
            let line = dark ? Color(red: 1.0, green: 0.93, blue: 0.85) : brown
            return WheelStyle(
                base: .cartoon(line: line, paper: dark ? Color(white: 0.16) : Color(red: 1.0, green: 0.97, blue: 0.93)),
                sectorFill: AnyShapeStyle(dark ? Color(white: 0.26) : Color(red: 1.0, green: 0.93, blue: 0.84)),
                hotFill: AnyShapeStyle(Color(red: 1.0, green: 0.55, blue: 0.2)),
                ink: dark ? inkLight : brown,
                hotInk: dark ? brown : .white,
                outline: line, outlineWidth: 2.5,
                hoverGlow: 0, pop: 4,
                centerFill: AnyShapeStyle(dark ? Color(white: 0.22) : Color.white),
                centerOutline: line,
                ringTrack: line.opacity(0.25))
        case .glass:
            // 透明玻璃：扇区几乎全透明，靠一圈左上亮、右下暗的细亮边和一道斜向反光体现质感；悬停是半透明的橙色玻璃
            return WheelStyle(
                base: .clearGlass,
                sectorFill: AnyShapeStyle(Color.white),
                hotFill: AnyShapeStyle(Color(red: 1.0, green: 0.5, blue: 0.15)),
                ink: dark ? inkLight : Color(white: 0.08),
                inkGlow: dark ? Color.black.opacity(0.6) : Color.white.opacity(0.85),
                sectorOpacity: dark ? 0.04 : 0.08, hotOpacity: 0.6,
                glassSheen: true, rim: true,
                hoverGlow: 16,
                centerFill: AnyShapeStyle(dark ? Color.white.opacity(0.06) : Color.white.opacity(0.14)),
                centerOutline: Color.white.opacity(0.85))
        }
    }
}

/// 一套轮盘外观的具体参数
struct WheelStyle {
    enum Base {
        case bevelGlass                        // 经典：毛玻璃 + 高光 + 内阴影 + 亮边
        case plainGlass                        // 简洁：毛玻璃 + 细白边 + 投影
        case clearGlass                        // 玻璃：更通透、更亮的边
        case cartoon(line: Color, paper: Color) // 卡通：实色底 + 粗描边 + 硬投影
        case flat(Color)                       // 简洁：实色底盘 + 一点柔和投影
    }

    var base: Base
    var sectorFill: AnyShapeStyle
    var hotFill: AnyShapeStyle
    var ink: Color
    var hotInk: Color = .white
    /// 文字背后的柔光（透明玻璃时保证在任何背景上都看得清）
    var inkGlow: Color? = nil
    /// 扇区整体透明度（玻璃）：填充和圆角描边先合成再统一变透明，重叠处才不会更深
    var sectorOpacity: Double = 1
    var hotOpacity: Double = 1
    /// 扇区圆角边带上的倒角高光（经典）
    var bevel = false
    /// 扇区的细描边（简洁、玻璃）
    var hairline: Color? = nil
    /// 扇区上的一道斜向反光（玻璃）
    var glassSheen = false
    /// 扇区外沿一圈细亮边，左上亮、右下暗（玻璃）
    var rim = false
    /// 磨砂颗粒的强度（简洁）
    var grain: Double = 0
    /// 扇区粗描边（卡通）
    var outline: Color? = nil
    var outlineWidth: CGFloat = 0
    var sectorShadow: Color = .clear
    /// 悬停时的橙色光晕半径
    var hoverGlow: CGFloat = 14
    /// 悬停时扇区往外弹出的距离
    var pop: CGFloat = 7
    var centerFill: AnyShapeStyle
    var centerOutline: Color? = nil
    var ringTrack: Color = Color.white.opacity(0.35)

    var isCartoon: Bool { if case .cartoon = base { return true } else { return false } }
}

/// 轮盘底座：按外观画不同的底
struct WheelBase: View {
    let style: WheelStyle
    let offscreen: Bool

    var body: some View {
        let d = (WheelMetrics.outerR + 18) * 2
        Group {
            switch style.base {
            case .bevelGlass:
                GlassBase(offscreen: offscreen)
            case .plainGlass:
                // 和系统菜单同一种材质：更不透明，偏中性的白 / 灰
                Group {
                    if offscreen { Circle().fill(.regularMaterial) }
                    else { BackdropBlur(material: .menu).clipShape(Circle()) }
                }
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.25), radius: 20, y: 8)
            case .clearGlass:
                // 透明玻璃不做模糊（模糊就成磨砂了）：只有很淡的一层白和高光边，背后看得清清楚楚
                ZStack {
                    Circle().fill(Color.white.opacity(0.06))
                    Circle().fill(LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0)],
                                                 startPoint: .topLeading, endPoint: .center))
                    Circle().strokeBorder(Color.black.opacity(0.1), lineWidth: 0.5)
                    Circle().strokeBorder(LinearGradient(colors: [Color.white, Color.white.opacity(0.1), Color.white.opacity(0.6)],
                                                         startPoint: .topLeading, endPoint: .bottomTrailing),
                                          lineWidth: 1.5)
                        .padding(0.5)
                }
                .shadow(color: .black.opacity(0.1), radius: 14, y: 5)
            case .flat(let color):
                Circle().fill(color).shadow(color: .black.opacity(0.22), radius: 16, y: 6)
            case .cartoon(let line, let paper):
                ZStack {
                    Circle().fill(line).offset(x: 5, y: 6)
                    Circle().fill(paper)
                    Circle().strokeBorder(line, lineWidth: 3.5)
                }
            }
        }
        .frame(width: d, height: d)
    }

    @ViewBuilder private var material: some View {
        if offscreen {
            Circle().fill(.ultraThinMaterial)   // 离屏渲染时 NSVisualEffectView 画不出来
        } else {
            BackdropBlur().clipShape(Circle())
        }
    }
}

/// 磨砂颗粒：一张随机灰点的小图，平铺在扇区上
enum Grain {
    static let image: NSImage = {
        let n = 96
        // RGBA 预乘：一半像素是半透明白点，一半是半透明黑点
        var bytes = [UInt8](repeating: 0, count: n * n * 4)
        var g = SystemRandomNumberGenerator()
        for i in 0..<(n * n) {
            let v = Int.random(in: 0...255, using: &g)
            let a = UInt8(abs(v - 128) * 2 > 255 ? 255 : abs(v - 128) * 2)
            let c: UInt8 = v > 128 ? a : 0
            bytes[i * 4] = c; bytes[i * 4 + 1] = c; bytes[i * 4 + 2] = c; bytes[i * 4 + 3] = a
        }
        let provider = CGDataProvider(data: Data(bytes) as CFData)!
        let cg = CGImage(width: n, height: n, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: n * 4,
                         space: CGColorSpaceCreateDeviceRGB(),
                         bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                         provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
        return NSImage(cgImage: cg, size: NSSize(width: n, height: n))
    }()
}
