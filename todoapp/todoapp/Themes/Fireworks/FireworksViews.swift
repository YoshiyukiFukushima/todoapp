//
//  FireworksViews.swift
//  todoapp
//
//  花火のテーマの色・形：火の色、玉のチェック、放射状の光の筋、夜空の星。
//  チェックすると、玉がふるえながら光をため（まわりから火の粉が吸いこまれる）、
//  ぎゅっと縮みきったところで、光の筋が中心からまっすぐ放射状に広がる（FireworksEffects）。
//

import SwiftUI

/// 花火 1 発の色（明るい・中・深い）
struct FireworkColor {
    let light: Color
    let mid: Color
    let deep: Color

    static let all: [FireworkColor] = [
        FireworkColor(light: Color(fixed: 0xFFE6EF), mid: Color(fixed: 0xF29BBB), deep: Color(fixed: 0xD0628D)), // 桃
        FireworkColor(light: Color(fixed: 0xE6F0FF), mid: Color(fixed: 0x97BCF4), deep: Color(fixed: 0x5784D4)), // 青
        FireworkColor(light: Color(fixed: 0xFFF4D8), mid: Color(fixed: 0xF6C878), deep: Color(fixed: 0xD69A35)), // 金
        FireworkColor(light: Color(fixed: 0xE3FBF1), mid: Color(fixed: 0x8EE2C0), deep: Color(fixed: 0x3DAE85)), // 緑
        FireworkColor(light: Color(fixed: 0xF0E8FF), mid: Color(fixed: 0xC3A9F6), deep: Color(fixed: 0x8A69D8)), // 紫
    ]

    /// タスクごとに決まった色
    static func pick(seed: UInt64) -> FireworkColor {
        var random = ThemeSeed(seed)
        return all[Int(random.next() * Double(all.count)) % all.count]
    }

    var tint: GlassTint {
        GlassTint(glassTop: DS.Fireworks.glass.glassTop, glassBottom: DS.Fireworks.glass.glassBottom,
                  sphereTint: DS.Fireworks.glass.sphereTint, sphereEdge: DS.Fireworks.glass.sphereEdge,
                  filledLight: light, filledMid: mid, filledDeep: deep)
    }
}

extension DS {
    enum Fireworks {
        // MARK: 夜空
        static let deepTop = Color(fixed: 0x0B1233)
        static let deepBottom = Color(fixed: 0x020309)
        static let glows: [(Color, Double)] = [
            (Color(fixed: 0x1E2B78), 0.5), (Color(fixed: 0x4A1F66), 0.35), (Color(fixed: 0x7A3A14), 0.22),
        ]
        static let star = Color(fixed: 0xF4F1E6)

        static let glass = GlassTint(
            glassTop: Color(fixed: 0x34374A).opacity(0.72), glassBottom: Color(fixed: 0x16171F).opacity(0.8),
            sphereTint: Color(fixed: 0x9DA3B8), sphereEdge: Color(fixed: 0x15161F),
            filledLight: Color(fixed: 0xFFF4D8), filledMid: Color(fixed: 0xF6C878), filledDeep: Color(fixed: 0xD69A35)
        )

        // MARK: 動き
        /// チェックしてから花火が開くまで（玉がふるえながら光をためる時間）
        static let chargeDuration: TimeInterval = 0.95
        /// チェックの花火が開いて消えるまで
        static let burstDuration: TimeInterval = 1.3
        /// 全部終わったとき、打ち上げ続ける時間
        static let celebrationSpread: TimeInterval = 3.4
    }
}

// MARK: - 玉のチェック

/// 未完了は暗いガラス玉。チェックすると、玉の中に光がだんだんたまり、開いた瞬間にそのタスクの花火の色に光る
struct FireworkCheck: View {
    let isCompleted: Bool
    let color: FireworkColor
    var isAnimated = true

    var body: some View {
        ZStack {
            BubbleSphere(isFilled: false, tint: DS.Fireworks.glass)
            // ためている光（だんだん強くなる）
            Circle()
                .fill(RadialGradient(colors: [color.light, color.mid.opacity(0.7), color.deep.opacity(0)],
                                     center: .center, startRadius: 0, endRadius: DS.Size.bubbleCheckbox * 0.5))
                .blendMode(.plusLighter)
                .opacity(isCompleted ? 1 : 0)
                .animation(isAnimated ? (isCompleted ? .easeIn(duration: DS.Fireworks.chargeDuration) : DS.Motion.fade) : nil,
                           value: isCompleted)
            BubbleSphere(isFilled: true, tint: color.tint)
                .opacity(isCompleted ? 1 : 0)
            Image(systemName: "checkmark")
                .font(DS.Typography.iconSmall)
                .foregroundStyle(.white)
                .shadow(color: color.deep.opacity(0.8), radius: 1)
                .opacity(isCompleted ? 1 : 0)
        }
        .animation(isAnimated ? (isCompleted ? .easeOut(duration: 0.3).delay(DS.Fireworks.chargeDuration) : DS.Motion.fade) : nil,
                   value: isCompleted)
    }
}

// MARK: - 放射状の花火（チェック・打ち上げで共通）

enum FireworkDrawing {
    /// 中心からまっすぐ放射状に広がる光の筋。外側の大きな輪と、内側の小さな輪（芯）の 2 重
    /// - Parameters:
    ///   - t: 開いてからの時間
    ///   - duration: 消えるまでの時間
    static func drawBurst(in context: GraphicsContext, center: CGPoint, radius: Double, rays: Int,
                          rotation: Double, color: FireworkColor, t: Double, duration: Double, lineWidth: Double) {
        guard t >= 0, t <= duration else { return }
        var c = context
        c.blendMode = .plusLighter

        // 開いた瞬間の光
        if t < 0.2 {
            let flash = 1 - t / 0.2
            let r = radius * 0.22
            c.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                   with: .radialGradient(Gradient(colors: [.white.opacity(0.8 * flash), color.light.opacity(0)]),
                                         center: center, startRadius: 0, endRadius: r))
        }

        let fade = 1 - smoothstep(0.55, 1, t / duration)
        drawRays(in: &c, center: center, radius: radius, rays: rays, rotation: rotation,
                 head: color.light, tail: color.mid, t: t, duration: duration, lineWidth: lineWidth, fade: fade, twinkle: true)
        // 芯（内側の短い筋）は、半分ずらした向きに明るい色で
        drawRays(in: &c, center: center, radius: radius * 0.5, rays: max(rays / 2, 6),
                 rotation: rotation + .pi / Double(rays), head: .white, tail: color.light,
                 t: t, duration: duration * 0.8, lineWidth: lineWidth * 0.8, fade: 1 - smoothstep(0.4, 0.8, t / duration), twinkle: false)
    }

    private static func drawRays(in c: inout GraphicsContext, center: CGPoint, radius: Double, rays: Int, rotation: Double,
                                 head headColor: Color, tail tailColor: Color, t: Double, duration: Double,
                                 lineWidth: Double, fade: Double, twinkle: Bool) {
        guard fade > 0.01 else { return }
        // 先は中心から勢いよく伸びる。根もとはしばらく中心に残り、あとから外へ追いかけて、筋がだんだん短くなる
        let head = radius * easeOutCubic(min(t / (duration * 0.45), 1))
        let tail = head * 0.8 * smoothstep(0.2, 0.95, t / duration)
        for index in 0..<rays {
            let angle = rotation + Double(index) / Double(rays) * .pi * 2
            let dir = CGVector(dx: cos(angle), dy: sin(angle))
            let from = CGPoint(x: center.x + dir.dx * tail, y: center.y + dir.dy * tail)
            let to = CGPoint(x: center.x + dir.dx * head, y: center.y + dir.dy * head)
            var line = Path()
            line.move(to: from)
            line.addLine(to: to)
            // 根もとは透けて、先ほど明るい光の筋
            let glow = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [tailColor.opacity(0), tailColor.opacity(0.3 * fade)]),
                startPoint: from, endPoint: to)
            let core = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [tailColor.opacity(0), tailColor.opacity(0.75 * fade), headColor.opacity(fade)]),
                startPoint: from, endPoint: to)
            c.stroke(line, with: glow, style: StrokeStyle(lineWidth: lineWidth * 2.4, lineCap: .butt))
            c.stroke(line, with: core, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
            // 先の光の粒（消えぎわはちかちか瞬く）
            var sparkle = fade
            if twinkle, t / duration > 0.5 {
                sparkle *= 0.45 + 0.55 * abs(sin(t * 26 + Double(index) * 1.7))
            }
            let r = lineWidth * 0.75
            c.fill(Path(ellipseIn: CGRect(x: to.x - r, y: to.y - r, width: r * 2, height: r * 2)),
                   with: .color(headColor.opacity(sparkle)))
        }
    }

    static func easeOutCubic(_ x: Double) -> Double {
        let u = 1 - x
        return 1 - u * u * u
    }

    static func smoothstep(_ a: Double, _ b: Double, _ x: Double) -> Double {
        let t = min(max((x - a) / (b - a), 0), 1)
        return t * t * (3 - 2 * t)
    }
}

// MARK: - 夜空の星（ちかちか瞬く）

struct FireworksSky: View {
    let time: TimeInterval

    private static let stars = AmbientDot.make(count: 46, seed: 0xF17E)

    var body: some View {
        Canvas { context, size in
            for star in Self.stars {
                // 星は画面の上 3 分の 2 に多く
                let y = star.y * star.y * size.height * 0.9
                let twinkle = 0.35 + 0.65 * (0.5 + 0.5 * sin(time * 1.6 * star.speed + star.phase))
                let r = 0.5 + star.size * 1.1
                context.fill(Path(ellipseIn: CGRect(x: star.x * size.width - r, y: y - r, width: r * 2, height: r * 2)),
                             with: .color(DS.Fireworks.star.opacity(0.55 * twinkle)))
            }
        }
    }
}
