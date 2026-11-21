//
//  ShishiViews.swift
//  todoapp
//
//  ししおどしのテーマの色・形：竹筒・筧（かけい）・石の小さな庭、水がたまって鳴るチェック、背景の水の輪。
//  チェックすると、竹筒に水が注がれ、重くなって少しずつ傾き、ぐっと倒れて水をこぼし、
//  戻るときに石を打つ（ShishiScene）。ためてから鳴るまでの「間」を楽しむテーマ。
//  「カコーン」の音と文字は ShishiEffects が出す。
//  ウィジェットでも使う（チェックと背景）。
//

import SwiftUI

extension DS {
    enum Shishi {
        // MARK: 背景（月夜の庭）
        static let deepTop = Color(fixed: 0x16292A)
        static let deepBottom = Color(fixed: 0x0B1513)
        static let glows: [(Color, Double)] = [
            (Color(fixed: 0x6FA35A), 0.38), (Color(fixed: 0xE8E2C0), 0.22), (Color(fixed: 0x3F8F86), 0.35),
        ]
        static let ripple = Color(fixed: 0xBFE3DA)

        // MARK: 竹・石・水
        static let bambooLight = Color(fixed: 0xD3E29A)
        static let bambooMid = Color(fixed: 0x8DB04A)
        static let bambooDeep = Color(fixed: 0x56762A)
        static let bambooLine = Color(fixed: 0x40581F)
        static let bambooInside = Color(fixed: 0xEDE6BE)
        static let stoneLight = Color(fixed: 0xA2A8AD)
        static let stoneDeep = Color(fixed: 0x575D62)
        static let water = Color(fixed: 0xA6DDF2)
        static let moss = Color(fixed: 0x6FA35A)

        static let glass = GlassTint(
            glassTop: Color(fixed: 0xA9C9B8).opacity(0.3), glassBottom: Color(fixed: 0x2A4A40).opacity(0.52),
            sphereTint: Color(fixed: 0xEEF6EE), sphereEdge: Color(fixed: 0x4A6A5C),
            filledLight: Color(fixed: 0xBEE0A6), filledMid: moss, filledDeep: Color(fixed: 0x4A7A3A)
        )

        // MARK: 動き（duration の中の割合）
        /// 水が注がれはじめてから、チェックが付くまで
        static let duration: TimeInterval = 2.7
        /// 水がいっぱいになって、倒れはじめるところ
        static let tipAt: Double = 0.52
        /// 倒れきったところ（ここから水がこぼれる）
        static let downAt: Double = 0.6
        /// 戻りはじめるところ
        static let returnAt: Double = 0.68
        /// 石を打つところ（カコーン）
        static let hitAt: Double = 0.77
        static var hitDelay: TimeInterval { duration * hitAt }
    }
}

// MARK: - ししおどしの庭

/// progress 0 で何も起きていない庭、1 で鳴り終わってチェックが付いた庭。アニメーションで 0→1 に動かすと、
/// 水が注がれる → 重くなって傾く → ぐっと倒れて水をこぼす → 戻って石を打つ → チェックが付く。
struct ShishiScene: View, Animatable {
    var progress: Double

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    /// 竹筒の傾き（度。正なら奥の端が下がり、石に当たる）
    static let restAngle = 24.0
    static let downAngle = -38.0

    var body: some View {
        Canvas { context, size in
            Self.draw(progress: progress, in: context, size: size)
        }
    }

    // MARK: 動きの計算

    /// 竹筒の傾きと、筒の中の水の量
    static func pose(at p: Double) -> (angle: Double, fill: Double) {
        let s = DS.Shishi.self
        if p < s.tipAt {
            // 水がたまるほど重くなって、少しずつ口が下がる
            let fill = Ease.smoothstep(0.04, s.tipAt, p)
            return (restAngle - 14 * fill * fill, fill)
        }
        if p < s.downAt {
            // ぐっと倒れる（だんだん速く）
            let k = Ease.inCubic((p - s.tipAt) / (s.downAt - s.tipAt))
            return (restAngle - 14 + (downAngle - restAngle + 14) * k, 1)
        }
        if p < s.returnAt {
            // 倒れたまま、水がこぼれていく
            let k = (p - s.downAt) / (s.returnAt - s.downAt)
            return (downAngle + sin(k * .pi) * 2, 1 - Ease.smoothstep(0, 1, k))
        }
        if p < s.hitAt {
            // 空になって、勢いよく戻る
            let k = Ease.inCubic((p - s.returnAt) / (s.hitAt - s.returnAt))
            return (downAngle + (restAngle - downAngle) * k, 0)
        }
        // 石に当たって、小さくはね返る
        let k = (p - s.hitAt) / (1 - s.hitAt)
        return (restAngle - 7 * sin(Ease.clamp(k * 2.2) * .pi) * (1 - k), 0)
    }

    // MARK: 描く

    static func draw(progress p: Double, in context: GraphicsContext, size: CGSize) {
        let s = min(size.width, size.height)
        let ox = (size.width - s) / 2, oy = (size.height - s) / 2
        func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: ox + s * x, y: oy + s * y) }
        let shishi = DS.Shishi.self
        let pose = pose(at: p)

        // まるい庭（タップできる場所の目印）
        let garden = Path(ellipseIn: CGRect(x: ox, y: oy, width: s, height: s))
        context.fill(garden, with: .radialGradient(Gradient(colors: [Color.white.opacity(0.16), Color.white.opacity(0.04)]),
                                                   center: pt(0.4, 0.3), startRadius: 0, endRadius: s * 0.7))
        context.stroke(garden, with: .color(.white.opacity(0.45)), lineWidth: max(0.8, s * 0.03))

        var scene = context
        scene.clip(to: garden)

        // 石
        let stone = Path(ellipseIn: CGRect(x: ox + s * 0.7, y: oy + s * 0.76, width: s * 0.32, height: s * 0.2))
        scene.fill(stone, with: .radialGradient(Gradient(colors: [shishi.stoneLight, shishi.stoneDeep]),
                                                center: pt(0.8, 0.78), startRadius: 0, endRadius: s * 0.22))

        // 竹筒を支える杭
        var post = Path()
        post.addRect(CGRect(x: ox + s * 0.51, y: oy + s * 0.58, width: s * 0.06, height: s * 0.42))
        scene.fill(post, with: .color(shishi.bambooDeep))

        // 筧（かけい）：左上から水を落とす細い竹
        let spout = Path(roundedRect: CGRect(x: ox - s * 0.05, y: oy + s * 0.14, width: s * 0.3, height: s * 0.075),
                         cornerRadius: s * 0.02)
        scene.fill(spout, with: .linearGradient(Gradient(colors: [shishi.bambooLight, shishi.bambooDeep]),
                                                startPoint: pt(0, 0.14), endPoint: pt(0, 0.215)))

        // 竹筒（口は左、奥の端は右で、石の上）
        let pivot = pt(0.54, 0.56)
        let radians = CGFloat(pose.angle * .pi / 180)
        let mouth = CGPoint(x: pivot.x - s * 0.4 * cos(radians), y: pivot.y - s * 0.4 * sin(radians))

        // 筧から口へ落ちる水（たまるあいだだけ）
        let pour = Ease.smoothstep(0, 0.04, p) * (1 - Ease.smoothstep(shishi.tipAt + 0.02, shishi.downAt + 0.06, p))
        if pour > 0 {
            var stream = Path()
            let top = pt(0.22, 0.2)
            let wave = sin(p * 90) * s * 0.008
            stream.move(to: top)
            stream.addQuadCurve(to: CGPoint(x: mouth.x + s * 0.02, y: mouth.y - s * 0.03),
                                control: CGPoint(x: top.x + wave, y: (top.y + mouth.y) / 2))
            scene.stroke(stream, with: .color(shishi.water.opacity(0.85 * pour)),
                         style: StrokeStyle(lineWidth: max(0.8, s * 0.035), lineCap: .round))
        }

        var tube = scene
        tube.translateBy(x: pivot.x, y: pivot.y)
        tube.rotate(by: .radians(radians))
        let half = s * 0.085
        var body = Path()
        body.move(to: CGPoint(x: -s * 0.45, y: -half))
        body.addLine(to: CGPoint(x: s * 0.36, y: -half))
        body.addLine(to: CGPoint(x: s * 0.36, y: half))
        body.addLine(to: CGPoint(x: -s * 0.33, y: half))
        body.closeSubpath()
        tube.fill(body, with: .linearGradient(Gradient(colors: [shishi.bambooLight, shishi.bambooMid, shishi.bambooDeep]),
                                              startPoint: CGPoint(x: 0, y: -half), endPoint: CGPoint(x: 0, y: half)))
        tube.stroke(body, with: .color(shishi.bambooLine), lineWidth: max(0.6, s * 0.018))
        // 節
        var node = Path()
        node.move(to: CGPoint(x: s * 0.08, y: -half))
        node.addLine(to: CGPoint(x: s * 0.08, y: half))
        tube.stroke(node, with: .color(shishi.bambooLine), lineWidth: max(0.8, s * 0.028))
        // 斜めに切った口（中に水が見える）
        var opening = tube
        opening.translateBy(x: -s * 0.39, y: 0)
        opening.rotate(by: .radians(atan2(2 * half, s * 0.12)))
        let rim = CGRect(x: -s * 0.1, y: -s * 0.032, width: s * 0.2, height: s * 0.064)
        opening.fill(Path(ellipseIn: rim), with: .color(shishi.bambooInside))
        if pose.fill > 0.02 {
            opening.fill(Path(ellipseIn: rim.insetBy(dx: s * 0.015, dy: s * 0.008)),
                         with: .color(shishi.water.opacity(0.35 + 0.6 * pose.fill)))
        }
        // 支点のくぎ
        tube.fill(Path(ellipseIn: CGRect(x: -s * 0.025, y: -s * 0.025, width: s * 0.05, height: s * 0.05)),
                  with: .color(shishi.bambooLine))

        // 倒れた口からこぼれる水
        if p > shishi.downAt - 0.02 && p < shishi.returnAt + 0.08 {
            for i in 0..<7 {
                let birth = shishi.downAt - 0.02 + Double(i) * 0.012
                let age = (p - birth) * shishi.duration
                guard age > 0, age < 0.32 else { continue }
                let x = mouth.x - s * 0.06 - s * 0.25 * age + s * 0.03 * Double(i % 3)
                let y = mouth.y + s * 0.02 + s * 7 * age * age
                let r = s * (0.03 - 0.002 * Double(i % 4))
                scene.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                           with: .color(shishi.water.opacity(0.9 * (1 - age / 0.32))))
            }
        }

        // 石を打った瞬間の、短い線
        let hitK = (p - shishi.hitAt) / 0.06
        if hitK > 0, hitK < 1 {
            var lines = Path()
            for (dx, dy) in [(-0.06, -0.12), (0.06, -0.14), (0.15, -0.08)] as [(Double, Double)] {
                let from = pt(0.86 + dx * (0.6 + hitK), 0.74 + dy * (0.6 + hitK))
                lines.move(to: from)
                lines.addLine(to: CGPoint(x: from.x + s * dx * 0.5, y: from.y + s * dy * 0.5))
            }
            var c = scene
            c.opacity = 1 - hitK
            c.stroke(lines, with: .color(.white), style: StrokeStyle(lineWidth: max(0.8, s * 0.03), lineCap: .round))
        }

        // 鳴り終わったら、苔色のチェック
        let check = Ease.outBack((p - shishi.hitAt - 0.05) / (1 - shishi.hitAt - 0.05), overshoot: 2)
        if check > 0 {
            let r = s * 0.17 * check
            let center = pt(0.77, 0.27)
            context.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                         with: .color(shishi.moss))
            var mark = Path()
            mark.move(to: CGPoint(x: center.x - r * 0.45, y: center.y + r * 0.02))
            mark.addLine(to: CGPoint(x: center.x - r * 0.1, y: center.y + r * 0.36))
            mark.addLine(to: CGPoint(x: center.x + r * 0.5, y: center.y - r * 0.32))
            context.stroke(mark, with: .color(.white), style: StrokeStyle(lineWidth: max(1, r * 0.26), lineCap: .round, lineJoin: .round))
        }
    }
}

struct ShishiCheck: View {
    let isCompleted: Bool
    var isAnimated = true

    var body: some View {
        ShishiScene(progress: isCompleted ? 1 : 0)
            .animation(isAnimated ? (isCompleted ? .linear(duration: DS.Shishi.duration) : .easeOut(duration: 0.35)) : nil,
                       value: isCompleted)
    }
}

// MARK: - 背景の水の輪（池にしずくが落ちたように、ゆっくり広がる）

struct ShishiRipples: View {
    let time: TimeInterval

    private static let dots = AmbientDot.make(count: 8, seed: 0x5415)

    var body: some View {
        Canvas { context, size in
            for dot in Self.dots {
                let period = 7.0 / dot.speed
                let k = ((time + dot.phase * period) / period).truncatingRemainder(dividingBy: 1)
                let center = CGPoint(x: dot.x * size.width, y: dot.y * size.height)
                for ring in 0..<2 {
                    let rk = k - Double(ring) * 0.12
                    guard rk > 0 else { continue }
                    let r = 6 + 46 * rk * (0.6 + dot.size * 0.6)
                    let rect = CGRect(x: center.x - r, y: center.y - r * 0.4, width: r * 2, height: r * 0.8)
                    context.stroke(Path(ellipseIn: rect), with: .color(DS.Shishi.ripple.opacity(0.14 * (1 - rk))), lineWidth: 1)
                }
            }
        }
    }
}
