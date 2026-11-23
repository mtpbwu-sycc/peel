import AppKit
import SwiftUI

/// 轮盘外观。只改样子，扇区、交互、动画都一样
enum WheelTheme: String, CaseIterable, Identifiable {
    case classic, simple, cartoon, midnight, paper, citrus
    var id: String { rawValue }

    var title: LText {
        switch self {
        case .classic: return LText("经典", "Classic")
        case .simple: return LText("磨砂", "Frosted")
        case .cartoon: return LText("卡通", "Cartoon")
        case .midnight: return LText("午夜", "Midnight")
        case .paper: return LText("纸张", "Paper")
        case .citrus: return LText("柑橘", "Citrus")
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
                ringTrack: dark ? Color.white.opacity(0.12) : Color.black.opacity(0.07), ringGlow: false)
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
                ringColor: Color(red: 1.0, green: 0.55, blue: 0.2), ringTrack: line.opacity(0.22), ringGlow: false)
        case .midnight:
            // 深夜蓝黑底，扇区是低调的深灰蓝，悬停时亮起橙色并发光
            return WheelStyle(
                base: .flat(Color(red: 0.07, green: 0.075, blue: 0.105)),
                sectorFill: AnyShapeStyle(LinearGradient(colors: [Color(red: 0.18, green: 0.19, blue: 0.25),
                                                                  Color(red: 0.12, green: 0.13, blue: 0.18)],
                                                         startPoint: .top, endPoint: .bottom)),
                hotFill: AnyShapeStyle(orange),
                ink: Color.white.opacity(0.88),
                hairline: Color.white.opacity(0.07),
                hoverGlow: 22, pop: 6,
                centerFill: AnyShapeStyle(Color(red: 0.1, green: 0.11, blue: 0.15)),
                centerOutline: Color.white.opacity(0.08),
                ringTrack: Color.white.opacity(0.08))
        case .paper:
            // 米白纸面 + 细黑线，单色；悬停变成实心黑
            let line = dark ? Color.white.opacity(0.35) : Color(white: 0.15).opacity(0.55)
            return WheelStyle(
                base: .flat(dark ? Color(white: 0.11) : Color(red: 0.975, green: 0.968, blue: 0.955)),
                sectorFill: AnyShapeStyle(dark ? Color(white: 0.15) : Color.white),
                hotFill: AnyShapeStyle(dark ? Color.white : Color(white: 0.1)),
                ink: dark ? Color.white.opacity(0.85) : Color(white: 0.12),
                hotInk: dark ? Color(white: 0.1) : .white,
                outline: line, outlineWidth: 0.8,
                hoverGlow: 0, pop: 3,
                centerFill: AnyShapeStyle(dark ? Color(white: 0.15) : Color.white),
                centerOutline: line,
                ringColor: dark ? .white : Color(white: 0.1),
                ringTrack: dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08), ringGlow: false)
        case .citrus:
            // 每个扇区一种水果色（橙、青柠、粉、葡萄……），悬停时变成饱和的同色
            return WheelStyle(
                base: .flat(dark ? Color(white: 0.12) : Color.white),
                sectorFill: AnyShapeStyle(Color.white),
                hotFill: AnyShapeStyle(orange),
                ink: dark ? Color.white.opacity(0.9) : Color(red: 0.2, green: 0.17, blue: 0.15),
                palette: WheelStyle.citrus(dark: dark),
                hoverGlow: 0, pop: 6,
                centerFill: AnyShapeStyle(dark ? Color(white: 0.18) : Color(red: 1.0, green: 0.98, blue: 0.95)),
                centerOutline: .clear,
                ringTrack: dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06), ringGlow: false)
        }
    }
}

/// 一套轮盘外观的具体参数
struct WheelStyle {
    enum Base {
        case bevelGlass                        // 经典：毛玻璃 + 高光 + 内阴影 + 亮边
        case plainGlass                        // 简洁：毛玻璃 + 细白边 + 投影
        case cartoon(line: Color, paper: Color) // 卡通：实色底 + 粗描边 + 硬投影
        case flat(Color)                       // 简洁：实色底盘 + 一点柔和投影
    }

    var base: Base
    var sectorFill: AnyShapeStyle
    var hotFill: AnyShapeStyle
    var ink: Color
    var hotInk: Color = .white
    /// 扇区整体透明度（玻璃）：填充和圆角描边先合成再统一变透明，重叠处才不会更深
    var sectorOpacity: Double = 1
    var hotOpacity: Double = 1
    /// 扇区圆角边带上的倒角高光（经典）
    var bevel = false
    /// 扇区的细描边（简洁、玻璃）
    var hairline: Color? = nil
    /// 磨砂颗粒的强度（简洁）
    var grain: Double = 0
    /// 每个扇区各自的颜色（柑橘）：(平时, 悬停)
    var palette: [(soft: Color, strong: Color)]? = nil
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
    /// 外圈进度条：颜色、底轨、是否发光
    var ringColor: Color = PeelColors.ring
    var ringTrack: Color = Color.white.opacity(0.35)
    var ringGlow = true
    /// 悬停光晕的颜色
    var glowColor: Color = .orange

    static func citrus(dark: Bool) -> [(soft: Color, strong: Color)] {
        let hues: [(Color, Color)] = [
            (Color(red: 1.0, green: 0.84, blue: 0.66), Color(red: 1.0, green: 0.55, blue: 0.15)),   // 橙
            (Color(red: 0.86, green: 0.94, blue: 0.62), Color(red: 0.5, green: 0.75, blue: 0.12)),  // 青柠
            (Color(red: 1.0, green: 0.82, blue: 0.86), Color(red: 0.94, green: 0.36, blue: 0.52)),  // 粉
            (Color(red: 0.87, green: 0.82, blue: 0.98), Color(red: 0.55, green: 0.4, blue: 0.9)),   // 葡萄
            (Color(red: 1.0, green: 0.94, blue: 0.62), Color(red: 0.96, green: 0.74, blue: 0.08)),  // 柠檬
            (Color(red: 0.76, green: 0.94, blue: 0.88), Color(red: 0.16, green: 0.68, blue: 0.54)), // 薄荷
        ]
        return dark ? hues.map { ($0.1.opacity(0.32), $0.1) } : hues
    }

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
