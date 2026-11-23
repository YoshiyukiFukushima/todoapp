//
//  WeatherViews.swift
//  todoapp
//
//  くもりのち晴れのテーマの色・形：青空、雲、にこにこの太陽、雲が晴れて太陽が出るチェック、流れる雲。
//  まだのタスクは小さな雲。チェックすると、雲が一度ふくらんでから横へ流れていき、
//  うしろから太陽がのぼって光がのび、にっこり笑う（WeatherClear）。
//  全部終えると、空に大きな太陽と虹が出る（WeatherEffects）。
//  いつも明るいテーマ。ウィジェットでも使う（チェックと背景）。
//

import SwiftUI

extension DS {
    enum Weather {
        // MARK: 背景（青空）
        static let deepTop = Color(fixed: 0x86BCEB)
        static let deepBottom = Color(fixed: 0xC9E5F8)
        static let glows: [(Color, Double)] = [
            (Color(fixed: 0xB9DDFB), 0.6), (Color(fixed: 0xF8E09A), 0.6), (Color(fixed: 0xFFFFFF), 0.65),
        ]

        static let glass = GlassTint(
            glassTop: Color(fixed: 0xF2FAFF).opacity(0.72), glassBottom: Color(fixed: 0xB6DCF7).opacity(0.55),
            sphereTint: Color(fixed: 0xF4FAFF), sphereEdge: Color(fixed: 0x8DB4D6),
            filledLight: Color(fixed: 0xFFF2A8), filledMid: Color(fixed: 0xFFCB3D), filledDeep: Color(fixed: 0xF39A1E)
        )

        // MARK: 雲と太陽
        static let cloud = Color(fixed: 0xFFFFFF)
        static let cloudShade = Color(fixed: 0xC5D2DF)
        static let sunLight = Color(fixed: 0xFFF3A6)
        static let sunMid = Color(fixed: 0xFFC93A)
        static let sunDeep = Color(fixed: 0xF5A01F)
        static let ray = Color(fixed: 0xFFC44A)
        static let face = Color(fixed: 0x6B3A12)
        static let cheek = Color(fixed: 0xFF8E7A)
        static let rainbow: [Color] = [
            Color(fixed: 0xEE7470), Color(fixed: 0xF4A85E), Color(fixed: 0xF5D766),
            Color(fixed: 0x7FCB8C), Color(fixed: 0x66A9EA), Color(fixed: 0x9C88E2),
        ]

        // MARK: 動き
        /// 雲が流れて、太陽が出て、笑うまで
        static let clearDuration: TimeInterval = 1.3
        /// 全部終えたとき、太陽と虹が出ている時間（このあと消える）
        static let celebrationHold: TimeInterval = 4.2
    }
}

// MARK: - 雲と太陽を描く

enum WeatherDrawing {
    /// もこもこの雲（下が平ら）。center は雲のまん中、width は横幅
    static func cloud(center: CGPoint, width: Double) -> Path {
        let w = width
        var p = Path()
        let baseY = center.y + w * 0.2
        p.addEllipse(in: CGRect(x: center.x - w * 0.5, y: baseY - w * 0.36, width: w * 0.46, height: w * 0.36))
        p.addEllipse(in: CGRect(x: center.x - w * 0.24, y: baseY - w * 0.56, width: w * 0.5, height: w * 0.5))
        p.addEllipse(in: CGRect(x: center.x + w * 0.06, y: baseY - w * 0.4, width: w * 0.44, height: w * 0.4))
        p.addRoundedRect(in: CGRect(x: center.x - w * 0.5, y: baseY - w * 0.2, width: w, height: w * 0.2),
                         cornerSize: CGSize(width: w * 0.1, height: w * 0.1))
        return p
    }

    static func drawCloud(in context: GraphicsContext, center: CGPoint, width: Double, opacity: Double = 1) {
        guard opacity > 0.01 else { return }
        var c = context
        c.opacity = opacity
        let shape = cloud(center: center, width: width)
        c.fill(shape, with: .linearGradient(Gradient(colors: [DS.Weather.cloud, DS.Weather.cloud, DS.Weather.cloudShade]),
                                            startPoint: CGPoint(x: center.x, y: center.y - width * 0.36),
                                            endPoint: CGPoint(x: center.x, y: center.y + width * 0.2)))
    }

    /// にこにこの太陽
    /// - Parameters:
    ///   - rays: 光ののび具合（0〜1）。1 本ずつ順にのびる
    ///   - face: 顔の出具合（0〜1）
    ///   - spin: 光の回転（ラジアン）
    static func drawSun(in context: GraphicsContext, center: CGPoint, radius: Double,
                        rays: Double, face: Double, spin: Double, rayCount: Int = 8) {
        guard radius > 0.2 else { return }
        // 光の筋（丸い先の短い棒）
        if rays > 0 {
            for index in 0..<rayCount {
                let p = Ease.outBack(rays * 1.6 - Double(index) / Double(rayCount) * 0.6, overshoot: 2)
                guard p > 0 else { continue }
                let angle = spin + Double(index) / Double(rayCount) * .pi * 2
                let inner = radius * 1.32, outer = radius * (1.32 + 0.42 * p)
                var line = Path()
                line.move(to: CGPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner))
                line.addLine(to: CGPoint(x: center.x + cos(angle) * outer, y: center.y + sin(angle) * outer))
                context.stroke(line, with: .color(DS.Weather.ray.opacity(min(p, 1))),
                               style: StrokeStyle(lineWidth: radius * 0.24, lineCap: .round))
            }
        }
        // ぼんやりした光
        let glowR = radius * 1.5
        context.fill(Path(ellipseIn: CGRect(x: center.x - glowR, y: center.y - glowR, width: glowR * 2, height: glowR * 2)),
                     with: .radialGradient(Gradient(colors: [DS.Weather.sunLight.opacity(0.55), DS.Weather.sunLight.opacity(0)]),
                                           center: center, startRadius: radius * 0.8, endRadius: glowR))
        let disc = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        context.fill(disc, with: .radialGradient(Gradient(colors: [DS.Weather.sunLight, DS.Weather.sunMid, DS.Weather.sunDeep]),
                                                 center: CGPoint(x: center.x - radius * 0.3, y: center.y - radius * 0.35),
                                                 startRadius: 0, endRadius: radius * 1.5))
        // つや
        var shine = context
        shine.translateBy(x: center.x - radius * 0.42, y: center.y - radius * 0.5)
        shine.rotate(by: .degrees(-30))
        shine.fill(Path(ellipseIn: CGRect(x: -radius * 0.28, y: -radius * 0.14, width: radius * 0.56, height: radius * 0.28)),
                   with: .color(.white.opacity(0.7)))

        guard face > 0 else { return }
        var f = context
        f.opacity = Ease.clamp(face)
        let s = max(face, 0.01)
        for dx in [-0.3, 0.3] {
            let r = radius * 0.09 * s
            f.fill(Path(ellipseIn: CGRect(x: center.x + dx * radius - r, y: center.y - radius * 0.08 - r * 1.2,
                                          width: r * 2, height: r * 2.4)), with: .color(DS.Weather.face))
            let cr = radius * 0.16 * s
            f.fill(Path(ellipseIn: CGRect(x: center.x + dx * 1.5 * radius - cr, y: center.y + radius * 0.2 - cr * 0.6,
                                          width: cr * 2, height: cr * 1.2)), with: .color(DS.Weather.cheek.opacity(0.55)))
        }
        var smile = Path()
        smile.move(to: CGPoint(x: center.x - radius * 0.17 * s, y: center.y + radius * 0.18))
        smile.addQuadCurve(to: CGPoint(x: center.x + radius * 0.17 * s, y: center.y + radius * 0.18),
                           control: CGPoint(x: center.x, y: center.y + radius * (0.18 + 0.2 * s)))
        f.stroke(smile, with: .color(DS.Weather.face), style: StrokeStyle(lineWidth: max(0.7, radius * 0.08), lineCap: .round))
    }
}

// MARK: - 雲が晴れて太陽が出るチェック

/// progress 0 で小さな雲、1 でにこにこの太陽。アニメーションで 0→1 に動かすと、
/// 雲が一度ふくらむ → 横へ流れて消える → うしろから太陽がのぼる → 光が 1 本ずつのびる → にっこり笑う。
struct WeatherClear: View, Animatable {
    var progress: Double

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            // 光と流れる雲がはみ出してもいいように、大きめのキャンバスに描く
            Canvas { context, canvasSize in
                Self.draw(progress: progress, in: context,
                          center: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2), size: size)
            }
            .frame(width: size * 2, height: size * 2)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            .allowsHitTesting(false)
        }
    }

    static func draw(progress: Double, in context: GraphicsContext, center: CGPoint, size: Double) {
        // 太陽：雲のうしろから、少し下からのぼる
        let rise = Ease.outBack((progress - 0.22) / 0.36, overshoot: 1.8)
        if rise > 0 {
            let sunCenter = CGPoint(x: center.x, y: center.y + size * 0.22 * (1 - Ease.clamp(rise)))
            let rays = Ease.clamp((progress - 0.48) / 0.34)
            let face = Ease.outBack((progress - 0.74) / 0.2, overshoot: 2.4)
            WeatherDrawing.drawSun(in: context, center: sunCenter, radius: size * 0.25 * rise,
                                   rays: rays, face: face, spin: -0.2 + 0.4 * Ease.clamp(progress))
        }

        // 雲：一度ふくらんで、右へ流れて消える
        let puff = sin(Ease.clamp(progress / 0.16) * .pi) * 0.12
        let drift = Ease.inCubic((progress - 0.12) / 0.5)
        let cloudCenter = CGPoint(x: center.x + size * 0.85 * drift, y: center.y + size * 0.04 - size * 0.08 * drift)
        WeatherDrawing.drawCloud(in: context, center: cloudCenter, width: size * 1.0 * (1 + puff - 0.25 * drift),
                                 opacity: 1 - Ease.smoothstep(0.35, 0.62, progress))
        // ちぎれて左へ流れる小さな雲
        if progress > 0.12, progress < 0.6 {
            let t = Ease.outCubic((progress - 0.12) / 0.48)
            WeatherDrawing.drawCloud(in: context, center: CGPoint(x: center.x - size * (0.15 + 0.55 * t), y: center.y - size * 0.02),
                                     width: size * 0.42 * (1 - 0.3 * t), opacity: 1 - t)
        }
    }
}

struct WeatherCheck: View {
    let isCompleted: Bool
    var isAnimated = true

    var body: some View {
        WeatherClear(progress: isCompleted ? 1 : 0)
            .animation(isAnimated ? (isCompleted ? .linear(duration: DS.Weather.clearDuration) : .easeInOut(duration: 0.45)) : nil,
                       value: isCompleted)
    }
}

// MARK: - 背景の雲（ゆっくり流れる）

struct WeatherClouds: View {
    let time: TimeInterval

    private static let dots = AmbientDot.make(count: 6, seed: 0x7EA7)

    var body: some View {
        Canvas { context, size in
            let travel = size.width + 300
            for dot in Self.dots {
                let distance = (time * 4 * dot.speed + dot.x * travel).truncatingRemainder(dividingBy: travel)
                let width = 110 + dot.size * 120
                WeatherDrawing.drawCloud(in: context, center: CGPoint(x: distance - 150, y: size.height * (0.08 + dot.y * 0.85)),
                                         width: width, opacity: 0.22 + 0.18 * dot.size)
            }
        }
    }
}
