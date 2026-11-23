//
//  SnowmanViews.swift
//  todoapp
//
//  雪だるまのテーマの色・形：初雪の朝の空、雪だるま、できあがっていく雪だるまのチェック、降る雪。
//  チェックすると、雪玉がころころ転がってきて、上から頭がぽすんと乗り、
//  目と鼻がついて、最後にマフラーがくるりと巻かれる（SnowmanBuild）。
//  いつも明るいテーマ。演出の層はない（チェックの中で完結する）。
//  ウィジェットでも使う（チェックと背景）。
//

import SwiftUI

extension DS {
    enum Snowman {
        // MARK: 背景（初雪の朝の空）
        static let deepTop = Color(fixed: 0xA7C9EE)
        static let deepBottom = Color(fixed: 0xEEF4FB)
        static let glows: [(Color, Double)] = [
            (Color(fixed: 0x84B2EA), 0.55), (Color(fixed: 0xC9B8F4), 0.6), (Color(fixed: 0xFFFFFF), 0.95),
        ]
        static let flake = Color(fixed: 0xFFFFFF)

        static let glass = GlassTint(
            glassTop: Color(fixed: 0xFFFFFF).opacity(0.78), glassBottom: Color(fixed: 0xDCE8F8).opacity(0.6),
            sphereTint: Color(fixed: 0xF4F8FF), sphereEdge: Color(fixed: 0x9FB6D6),
            // ＋ボタンは、白い空に埋もれないようマフラーの赤にする
            filledLight: Color(fixed: 0xFFB8C0), filledMid: Color(fixed: 0xE14E5B), filledDeep: Color(fixed: 0xB53441)
        )

        // MARK: 雪だるま
        static let snow = Color(fixed: 0xFFFFFF)
        static let snowShade = Color(fixed: 0xCAD9EC)
        static let eye = Color(fixed: 0x283247)
        static let nose = Color(fixed: 0xF2873A)
        static let cheek = Color(fixed: 0xF6A2B4)
        static let scarf = Color(fixed: 0xE14E5B)
        static let scarfDeep = Color(fixed: 0xB53441)
        static let button = Color(fixed: 0x3A4458)

        // MARK: 動き
        /// 雪玉が転がってきて、頭が乗って、マフラーを巻くまで
        static let buildDuration: TimeInterval = 1.45
        /// buildDuration の中で、雪玉が止まるところ
        static let rolledAt: Double = 0.32
        /// buildDuration の中で、頭が乗るところ
        static let headAt: Double = 0.56
        /// 頭が乗るまでの時間（チェックがぽすんと沈む）
        static var headDelay: TimeInterval { buildDuration * headAt }
    }
}

// MARK: - できあがっていく雪だるま

/// progress 0 で空のすりガラス玉、1 で雪だるま。アニメーションで 0→1 に動かすと、
/// 雪玉が左から転がってくる → 頭が上から落ちてきてぽすんと乗る → 目・鼻・ほっぺ → マフラーをくるりと巻く。
struct SnowmanBuild: View, Animatable {
    var progress: Double

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                BubbleSphere(isFilled: false, tint: DS.Snowman.glass)
                    .frame(width: size, height: size)
                    .opacity(1 - Ease.smoothstep(0.05, 0.3, progress))
                // 頭は上から落ちてくるので、大きめのキャンバスに描く
                Canvas { context, canvasSize in
                    Self.draw(progress: progress, in: context,
                              origin: CGPoint(x: (canvasSize.width - size) / 2, y: (canvasSize.height - size) / 2), size: size)
                }
                .frame(width: size * 2, height: size * 2.6)
                .allowsHitTesting(false)
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }

    /// origin は、チェックの四角の左上（キャンバスの中の座標）
    static func draw(progress: Double, in context: GraphicsContext, origin: CGPoint, size: Double) {
        guard progress > 0 else { return }
        let rolledAt = DS.Snowman.rolledAt, headAt = DS.Snowman.headAt
        func point(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: origin.x + x * size, y: origin.y + y * size) }

        // 体：左から転がってきながら大きくなる
        let roll = Ease.outCubic(progress / rolledAt)
        let bodyR = size * (0.12 + 0.15 * roll)
        let bodyX = -0.55 + 0.55 * roll
        // 頭が乗った瞬間、体も少しつぶれる
        let landT = (progress - headAt) / 0.14
        let squash = landT > 0 && landT < 1 ? sin(landT * .pi) * 0.12 : 0
        let groundY = 0.98
        let bodyCenter = point(0.5 + bodyX, groundY - (bodyR / size) * (1 - squash))

        // 地面の影
        let shadowW = bodyR * 2.1
        context.fill(Path(ellipseIn: CGRect(x: bodyCenter.x - shadowW / 2, y: origin.y + groundY * size - size * 0.04,
                                            width: shadowW, height: size * 0.08)),
                     with: .color(DS.Snowman.snowShade.opacity(0.7 * roll)))

        drawBall(in: context, center: bodyCenter, rx: bodyR * (1 + squash * 0.6), ry: bodyR * (1 - squash), spin: roll * 6)
        // ボタン
        let buttons = Ease.smoothstep(headAt + 0.1, headAt + 0.22, progress)
        if buttons > 0 {
            for dy in [-0.05, 0.08] {
                let r = size * 0.028 * buttons
                context.fill(Path(ellipseIn: CGRect(x: bodyCenter.x - r, y: bodyCenter.y + dy * size - r, width: r * 2, height: r * 2)),
                             with: .color(DS.Snowman.button))
            }
        }

        // 頭：上から落ちてきて、ぽすんと乗る
        guard progress > rolledAt - 0.02 else { return }
        let headR = size * 0.19
        let fall = Ease.inCubic((progress - rolledAt) / (headAt - rolledAt))
        let restY = bodyCenter.y - bodyR * (1 - squash) - headR * 0.78
        let headY = restY - (1 - fall) * size * 1.1
        let headSquash = landT > 0 && landT < 1 ? sin(landT * .pi) * 0.16 : 0
        let headCenter = CGPoint(x: bodyCenter.x, y: headY + headR * headSquash * 0.5)
        drawBall(in: context, center: headCenter, rx: headR * (1 + headSquash * 0.5), ry: headR * (1 - headSquash), spin: 0)

        // 乗った瞬間の雪けむり
        if landT > 0, landT < 1.6 {
            let puff = landT / 1.6
            for index in 0..<6 {
                let angle = Double.pi * (0.9 + Double(index) * 0.24) + (index % 2 == 0 ? 0 : .pi * 0.08)
                let dist = size * (0.22 + 0.26 * Ease.outCubic(puff))
                let p = CGPoint(x: headCenter.x + cos(angle) * dist * (index < 3 ? -1 : 1) * 0.9,
                                y: headCenter.y + headR * 0.7 + sin(angle) * dist * 0.25)
                let r = size * 0.04 * (1 - puff * 0.5)
                context.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                             with: .color(.white.opacity(0.9 * (1 - puff))))
            }
        }

        // 顔：目・ほっぺ・鼻がぽんと出る
        let face = Ease.outBack((progress - headAt - 0.06) / 0.14, overshoot: 2.5)
        if face > 0 {
            let s = face
            for dx in [-0.075, 0.075] {
                let r = size * 0.026 * s
                context.fill(Path(ellipseIn: CGRect(x: headCenter.x + dx * size - r, y: headCenter.y - size * 0.035 - r,
                                                    width: r * 2, height: r * 2)), with: .color(DS.Snowman.eye))
                let cr = size * 0.035 * s
                context.fill(Path(ellipseIn: CGRect(x: headCenter.x + dx * 1.5 * size - cr, y: headCenter.y + size * 0.04 - cr * 0.7,
                                                    width: cr * 2, height: cr * 1.4)), with: .color(DS.Snowman.cheek.opacity(0.8)))
            }
            var nose = Path()
            let noseBase = CGPoint(x: headCenter.x, y: headCenter.y + size * 0.015)
            nose.move(to: CGPoint(x: noseBase.x - size * 0.01, y: noseBase.y - size * 0.025 * s))
            nose.addLine(to: CGPoint(x: noseBase.x + size * 0.11 * s, y: noseBase.y + size * 0.005))
            nose.addLine(to: CGPoint(x: noseBase.x - size * 0.01, y: noseBase.y + size * 0.025 * s))
            nose.closeSubpath()
            context.fill(nose, with: .color(DS.Snowman.nose))
        }

        // マフラー：首にくるりと巻いて、しっぽがひらりと揺れて止まる
        let wrap = Ease.smoothstep(headAt + 0.14, headAt + 0.32, progress)
        if wrap > 0 {
            let neckY = bodyCenter.y - bodyR * (1 - squash) + size * 0.01
            let width = headR * 2.1
            var band = Path()
            band.addRoundedRect(in: CGRect(x: headCenter.x - width / 2, y: neckY - size * 0.045,
                                           width: width * wrap, height: size * 0.09),
                                cornerSize: CGSize(width: size * 0.04, height: size * 0.04))
            context.fill(band, with: .color(DS.Snowman.scarf))
            // しま
            if wrap > 0.5 {
                for dx in [-0.06, 0.04] {
                    context.fill(Path(CGRect(x: headCenter.x + dx * size, y: neckY - size * 0.045, width: size * 0.025, height: size * 0.09)),
                                 with: .color(DS.Snowman.scarfDeep.opacity(0.5)))
                }
            }
            let tailT = Ease.clamp((progress - headAt - 0.26) / (1 - headAt - 0.26))
            if tailT > 0 {
                let swing = sin(tailT * 9) * 0.5 * (1 - tailT)
                var c = context
                c.translateBy(x: headCenter.x + width * 0.22, y: neckY)
                c.rotate(by: .radians(0.15 + swing))
                c.fill(Path(roundedRect: CGRect(x: -size * 0.04, y: 0, width: size * 0.08, height: size * 0.24 * Ease.outCubic(tailT * 2)),
                            cornerRadius: size * 0.03),
                       with: .color(DS.Snowman.scarfDeep))
            }
        }
    }

    /// 雪玉（下にうっすら青いかげ、左上につや）
    private static func drawBall(in context: GraphicsContext, center: CGPoint, rx: Double, ry: Double, spin: Double) {
        let rect = CGRect(x: center.x - rx, y: center.y - ry, width: rx * 2, height: ry * 2)
        let ball = Path(ellipseIn: rect)
        context.fill(ball, with: .radialGradient(
            Gradient(colors: [DS.Snowman.snow, DS.Snowman.snow, DS.Snowman.snowShade]),
            center: CGPoint(x: center.x - rx * 0.35, y: center.y - ry * 0.4), startRadius: 0, endRadius: max(rx, ry) * 1.7))
        context.stroke(ball, with: .color(DS.Snowman.snowShade.opacity(0.9)), lineWidth: max(0.6, rx * 0.05))
        // 転がっているときの雪のでこぼこ（回って見える）
        if spin > 0 {
            var c = context
            c.clip(to: ball)
            for index in 0..<3 {
                let angle = spin + Double(index) * 2.1
                let p = CGPoint(x: center.x + cos(angle) * rx * 0.55, y: center.y + sin(angle) * ry * 0.55)
                let r = rx * 0.12
                c.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                       with: .color(DS.Snowman.snowShade.opacity(0.35)))
            }
        }
    }
}

struct SnowmanCheck: View {
    let isCompleted: Bool
    var isAnimated = true

    var body: some View {
        SnowmanBuild(progress: isCompleted ? 1 : 0)
            .animation(isAnimated ? (isCompleted ? .linear(duration: DS.Snowman.buildDuration) : .easeOut(duration: 0.3)) : nil,
                       value: isCompleted)
    }
}

// MARK: - 降る雪（ゆらゆら揺れながら、ゆっくり落ちる）

struct SnowmanFlakes: View {
    let time: TimeInterval

    private static let flakes = AmbientDot.make(count: 44, seed: 0x5A0)

    var body: some View {
        Canvas { context, size in
            let travel = size.height + 20
            for flake in Self.flakes {
                let distance = (time * 18 * flake.speed + flake.y * travel).truncatingRemainder(dividingBy: travel)
                let y = distance - 10
                let x = flake.x * size.width + sin(time * 0.8 * flake.speed + flake.phase) * 14
                let r = 1.2 + flake.size * 2.6
                // 明るい背景でも見えるよう、うっすら青いふちをつける
                context.fill(Path(ellipseIn: CGRect(x: x - r - 0.6, y: y - r - 0.6, width: (r + 0.6) * 2, height: (r + 0.6) * 2)),
                             with: .color(Color(fixed: 0x9FB8DA).opacity(0.25)))
                context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                             with: .color(DS.Snowman.flake.opacity(0.95)))
            }
        }
    }
}
