//
//  PlanetViews.swift
//  todoapp
//
//  惑星のテーマの色・形：星雲の夜空、輪のある惑星、生まれる惑星のチェック、瞬く星。
//  チェックすると、まわりの星くずが渦を巻いて集まり、ぽんと丸い惑星になって、輪がくるりと広がる（PlanetBirth）。
//  惑星の色はタスクごとに決まる。演出の層はない（チェックの中で完結する）。
//  ウィジェットでも使う（チェックと背景）。
//

import SwiftUI

extension DS {
    enum Planet {
        // MARK: 背景（星雲の夜空）
        static let deepTop = Color(fixed: 0x241C66)
        static let deepBottom = Color(fixed: 0x070A1F)
        static let glows: [(Color, Double)] = [
            (Color(fixed: 0x6A4CFF), 0.6), (Color(fixed: 0x0C8FB8), 0.45), (Color(fixed: 0xB8407A), 0.38),
        ]
        static let star = Color(fixed: 0xF3F1FF)

        static let glass = GlassTint(
            glassTop: Color(fixed: 0x9C92F0).opacity(0.3), glassBottom: Color(fixed: 0x22306A).opacity(0.55),
            sphereTint: Color(fixed: 0xE8E4FF), sphereEdge: Color(fixed: 0x3C3F86),
            filledLight: Color(fixed: 0xFFC7A8), filledMid: Color(fixed: 0xF0825A), filledDeep: Color(fixed: 0xB24A3A)
        )

        // MARK: 動き
        /// 星くずが集まって、惑星になって、輪が広がるまで
        static let birthDuration: TimeInterval = 1.25
        /// birthDuration の中で、惑星がぽんと生まれるところ
        static let formAt: Double = 0.42
    }
}

// MARK: - 惑星の色（タスクごとに決まる）

struct PlanetPalette: Equatable {
    let light: Color
    let mid: Color
    let deep: Color
    /// 表面のしま模様
    let band: Color
    /// 輪
    let ring: Color

    static let all: [PlanetPalette] = [
        // 夕焼け色（土星のような）
        PlanetPalette(light: Color(fixed: 0xFFD2B0), mid: Color(fixed: 0xF0855C), deep: Color(fixed: 0xA8433A),
                      band: Color(fixed: 0xC9603F), ring: Color(fixed: 0xF7D9A6)),
        // 水色
        PlanetPalette(light: Color(fixed: 0xC8F4F2), mid: Color(fixed: 0x4CC0C6), deep: Color(fixed: 0x1F6F86),
                      band: Color(fixed: 0x2F96A6), ring: Color(fixed: 0xD8F0FF)),
        // すみれ色
        PlanetPalette(light: Color(fixed: 0xE6D8FF), mid: Color(fixed: 0xA88BF2), deep: Color(fixed: 0x5B45B0),
                      band: Color(fixed: 0x8366D6), ring: Color(fixed: 0xF6D8F2)),
        // 金色
        PlanetPalette(light: Color(fixed: 0xFFF0B8), mid: Color(fixed: 0xF2C35A), deep: Color(fixed: 0xA8711F),
                      band: Color(fixed: 0xD69A35), ring: Color(fixed: 0xFFF4D6)),
    ]

    static func pick(seed: UInt64) -> PlanetPalette {
        var random = ThemeSeed(seed ^ 0x91A7E7)
        return all[Int(random.next() * Double(all.count)) % all.count]
    }
}

// MARK: - 惑星を描く

enum PlanetDrawing {
    /// 輪の傾き
    static let tilt: Double = -0.38

    /// 輪のある惑星。輪は、奥の半分 → 惑星 → 手前の半分の順に描いて、惑星に巻きついて見せる
    /// - Parameters:
    ///   - radius: 惑星の半径
    ///   - ring: 輪の広がり具合（0 で輪なし、1 で広がりきる）
    static func draw(in context: GraphicsContext, center: CGPoint, radius: Double, palette: PlanetPalette,
                     ring: Double, ringTilt: Double = tilt) {
        guard radius > 0.2 else { return }
        if ring > 0.01 { drawRing(in: context, center: center, radius: radius, palette: palette, open: ring, tilt: ringTilt, front: false) }

        let disc = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        context.fill(disc, with: .radialGradient(
            Gradient(colors: [palette.light, palette.mid, palette.deep]),
            center: CGPoint(x: center.x - radius * 0.35, y: center.y - radius * 0.4), startRadius: 0, endRadius: radius * 1.6))
        // しま模様（惑星の丸の中だけ）
        var bands = context
        bands.clip(to: disc)
        bands.translateBy(x: center.x, y: center.y)
        bands.rotate(by: .radians(ringTilt))
        for (y, h, alpha) in [(-0.42, 0.14, 0.35), (0.05, 0.2, 0.3), (0.45, 0.12, 0.28)] as [(Double, Double, Double)] {
            bands.fill(Path(CGRect(x: -radius * 1.2, y: radius * y, width: radius * 2.4, height: radius * h)),
                       with: .color(palette.band.opacity(alpha)))
        }
        // 夜側のかげ と つや
        context.fill(disc, with: .radialGradient(
            Gradient(colors: [.clear, .clear, .black.opacity(0.28)]),
            center: CGPoint(x: center.x - radius * 0.3, y: center.y - radius * 0.35), startRadius: 0, endRadius: radius * 1.5))
        let shine = CGRect(x: center.x - radius * 0.58, y: center.y - radius * 0.62, width: radius * 0.5, height: radius * 0.3)
        context.fill(Path(ellipseIn: shine), with: .color(.white.opacity(0.55)))

        if ring > 0.01 { drawRing(in: context, center: center, radius: radius, palette: palette, open: ring, tilt: ringTilt, front: true) }
    }

    private static func drawRing(in context: GraphicsContext, center: CGPoint, radius: Double, palette: PlanetPalette,
                                 open: Double, tilt: Double, front: Bool) {
        var c = context
        c.translateBy(x: center.x, y: center.y)
        c.rotate(by: .radians(tilt))
        let rx = radius * (1.15 + 0.6 * open)
        let ry = radius * 0.42 * open
        // 手前の半分は下側、奥の半分は上側
        c.clip(to: Path(CGRect(x: -rx * 2, y: front ? 0 : -rx * 2, width: rx * 4, height: rx * 2)))
        let ellipse = Path(ellipseIn: CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2))
        let alpha = min(open * 1.6, 1) * (front ? 1 : 0.75)
        c.stroke(ellipse, with: .linearGradient(Gradient(colors: [palette.ring.opacity(0.4 * alpha), palette.ring.opacity(alpha),
                                                                   palette.ring.opacity(0.55 * alpha)]),
                                                startPoint: CGPoint(x: -rx, y: 0), endPoint: CGPoint(x: rx, y: 0)),
                 lineWidth: radius * 0.24)
        let inner = Path(ellipseIn: CGRect(x: -rx * 0.86, y: -ry * 0.86, width: rx * 1.72, height: ry * 1.72))
        c.stroke(inner, with: .color(palette.ring.opacity(0.45 * alpha)), lineWidth: radius * 0.06)
    }
}

// MARK: - 生まれる惑星のチェック

/// progress 0 で空のガラス玉、1 で輪のある惑星。アニメーションで 0→1 に動かすと、
/// まわりの星くずが渦を巻いて集まる → ぽんと惑星が生まれる → 輪がくるりと広がる。
struct PlanetBirth: View, Animatable {
    var progress: Double
    let palette: PlanetPalette

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                // 空のガラス玉（星くずが集まるにつれて消える）
                BubbleSphere(isFilled: false, tint: DS.Planet.glass)
                    .frame(width: size, height: size)
                    .opacity(1 - Ease.smoothstep(0.25, DS.Planet.formAt, progress))
                // 輪が四角からはみ出してもいいように、大きめのキャンバスに描く
                Canvas { context, canvasSize in
                    Self.draw(progress: progress, palette: palette, in: context,
                              center: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2), size: size)
                }
                .frame(width: size * 2.2, height: size * 2.2)
                .allowsHitTesting(false)
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }

    static func draw(progress: Double, palette: PlanetPalette, in context: GraphicsContext, center: CGPoint, size: Double) {
        let formAt = DS.Planet.formAt
        let radius = size * 0.34

        // 星くず：外から渦を巻いて中心へ集まる
        if progress > 0, progress < formAt + 0.06 {
            var c = context
            c.blendMode = .plusLighter
            let gather = Ease.clamp(progress / formAt)
            for index in 0..<12 {
                let pull = Ease.inCubic(Ease.clamp(gather * 1.1 - Double(index % 4) * 0.03))
                let angle = Double(index) * 0.5236 + pull * 3.6
                let distance = size * (0.95 - 0.9 * pull)
                let point = CGPoint(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance * 0.8)
                let r = size * (0.035 + 0.02 * Double(index % 3))
                let alpha = Ease.smoothstep(0, 0.2, gather) * (1 - Ease.smoothstep(formAt - 0.02, formAt + 0.06, progress))
                c.fill(Path(ellipseIn: CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)),
                       with: .color((index % 2 == 0 ? palette.light : .white).opacity(alpha)))
            }
        }

        // 生まれる瞬間の光
        let flashT = (progress - formAt) / 0.18
        if flashT > 0, flashT < 1 {
            var c = context
            c.blendMode = .plusLighter
            let r = size * (0.3 + 0.5 * flashT)
            c.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                   with: .radialGradient(Gradient(colors: [.white.opacity(0.7 * (1 - flashT)), palette.light.opacity(0)]),
                                         center: center, startRadius: 0, endRadius: r))
        }

        // 惑星がぽんと生まれ、輪がくるりと広がる
        let grow = Ease.outBack((progress - formAt) / 0.22, overshoot: 2.2)
        let ring = Ease.outBack((progress - formAt - 0.16) / (1 - formAt - 0.16), overshoot: 1.4)
        let tilt = PlanetDrawing.tilt - 0.5 * (1 - Ease.clamp(ring))
        PlanetDrawing.draw(in: context, center: center, radius: radius * grow, palette: palette, ring: ring, ringTilt: tilt)
    }
}

struct PlanetCheck: View {
    let isCompleted: Bool
    let palette: PlanetPalette
    var isAnimated = true

    var body: some View {
        PlanetBirth(progress: isCompleted ? 1 : 0, palette: palette)
            .animation(isAnimated ? (isCompleted ? .linear(duration: DS.Planet.birthDuration) : .easeOut(duration: 0.3)) : nil,
                       value: isCompleted)
    }
}

// MARK: - 背景の星（ちかちか瞬く・ときどき流れ星）

struct PlanetStars: View {
    let time: TimeInterval

    private static let stars = AmbientDot.make(count: 60, seed: 0x91A7)

    var body: some View {
        Canvas { context, size in
            for star in Self.stars {
                let twinkle = 0.3 + 0.7 * (0.5 + 0.5 * sin(time * 1.3 * star.speed + star.phase))
                let r = 0.4 + star.size * 1.2
                let point = CGPoint(x: star.x * size.width, y: star.y * size.height)
                context.fill(Path(ellipseIn: CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)),
                             with: .color(DS.Planet.star.opacity(0.6 * twinkle)))
            }
            // 9 秒に 1 度、右上から左下へ流れ星
            let cycle = 9.0
            let t = time.truncatingRemainder(dividingBy: cycle)
            if t < 0.9 {
                let p = t / 0.9
                let round = Int(time / cycle)
                var random = ThemeSeed(UInt64(round) &+ 0x5EED)
                let start = CGPoint(x: size.width * random.next(in: 0.55...0.95), y: size.height * random.next(in: 0.05...0.35))
                let head = CGPoint(x: start.x - 150 * p, y: start.y + 90 * p)
                let tail = CGPoint(x: head.x + 40, y: head.y - 24)
                var line = Path()
                line.move(to: tail)
                line.addLine(to: head)
                let alpha = sin(p * .pi) * 0.8
                context.stroke(line, with: .linearGradient(Gradient(colors: [.white.opacity(0), .white.opacity(alpha)]),
                                                           startPoint: tail, endPoint: head), lineWidth: 1.2)
            }
        }
    }
}
