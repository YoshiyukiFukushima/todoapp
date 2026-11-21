//
//  PaperPlaneViews.swift
//  todoapp
//
//  紙飛行機のテーマの色・形：紙、紙飛行機、折りたたまれるチェック、背景の雲。
//  チェックすると、白い紙がくしゃっと折りたたまれて紙飛行機になり、一度少し沈む（PaperFold）。
//  そこから点線の軌跡を残してぐいっと空へ飛んでいく動きは PaperPlaneEffects が描く。
//  ウィジェットでも使う（チェックと背景）。
//

import SwiftUI

extension DS {
    enum PaperPlane {
        // MARK: 背景（夜明け前の空）
        static let deepTop = Color(fixed: 0x1B2B4C)
        static let deepBottom = Color(fixed: 0x0F182C)
        static let glows: [(Color, Double)] = [
            (Color(fixed: 0x5B8DEF), 0.5), (Color(fixed: 0xF0B27A), 0.28), (Color(fixed: 0x9FB8E8), 0.32),
        ]
        static let paper = Color(fixed: 0xFBFCFF)
        static let paperShade = Color(fixed: 0xD5DCEA)
        static let crease = Color(fixed: 0xAEB8CC)
        static let trail = Color(fixed: 0xE6EEFF)

        static let glass = GlassTint(
            glassTop: Color(fixed: 0xB4C6EA).opacity(0.32), glassBottom: Color(fixed: 0x2E4170).opacity(0.5),
            sphereTint: Color(fixed: 0xF0F5FF), sphereEdge: Color(fixed: 0x4E6496),
            filledLight: Color(fixed: 0xC9DAFF), filledMid: Color(fixed: 0x5B8DEF), filledDeep: Color(fixed: 0x3462C4)
        )

        // MARK: 動き
        /// 折りたたまれて、沈んで、飛び立つまで（チェックの中の動き）
        static let foldDuration: TimeInterval = 1.0
        /// foldDuration の中で、折りあがるところ
        static let foldedAt: Double = 0.5
        /// foldDuration の中で、飛び立つところ（ここから先は PaperPlaneEffects が描く）
        static let launchAt: Double = 0.78
        static var launchDelay: TimeInterval { foldDuration * launchAt }
        /// 飛び立ってから、画面の外へ出るまで
        static let flightDuration: TimeInterval = 1.15
        /// 点線の軌跡が消えるまで
        static let trailFade: TimeInterval = 0.7
    }
}

// MARK: - 紙と紙飛行機の形

/// 紙（正方形）と紙飛行機（上から見た形）を、同じ数の頂点で表す。
/// 頂点を少しずつ動かすと、紙が折りたたまれて紙飛行機になる。座標は 0〜1 の正方形の中
enum PaperPlaneForm {
    /// 紙：左上・上・右上・右・右下・下・左下・左
    static let sheet: [CGPoint] = [
        CGPoint(x: 0, y: 0), CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: 1, y: 0.5),
        CGPoint(x: 1, y: 1), CGPoint(x: 0.5, y: 1), CGPoint(x: 0, y: 1), CGPoint(x: 0, y: 0.5),
    ]
    /// 紙飛行機（右が機首）
    static let plane: [CGPoint] = [
        CGPoint(x: 0.04, y: 0.14), CGPoint(x: 0.55, y: 0.38), CGPoint(x: 1, y: 0.5), CGPoint(x: 1, y: 0.5),
        CGPoint(x: 1, y: 0.5), CGPoint(x: 0.55, y: 0.62), CGPoint(x: 0.04, y: 0.86), CGPoint(x: 0.3, y: 0.5),
    ]
    /// くしゃっとするときの、頂点ごとのずれ
    static let crumple: [CGPoint] = [
        CGPoint(x: 0.12, y: 0.1), CGPoint(x: -0.06, y: 0.14), CGPoint(x: -0.12, y: 0.06), CGPoint(x: -0.1, y: -0.08),
        CGPoint(x: -0.12, y: -0.1), CGPoint(x: 0.08, y: -0.14), CGPoint(x: 0.12, y: -0.06), CGPoint(x: 0.14, y: 0.04),
    ]

    /// fold 0 で紙、1 で紙飛行機。中ほどで少しくしゃっとなる
    static func points(fold: Double) -> [CGPoint] {
        let crush = sin(Ease.clamp(fold) * .pi) * 0.9
        return (0..<sheet.count).map { i in
            CGPoint(x: sheet[i].x + (plane[i].x - sheet[i].x) * fold + crumple[i].x * crush,
                    y: sheet[i].y + (plane[i].y - sheet[i].y) * fold + crumple[i].y * crush)
        }
    }

    /// 頂点（0〜1）を、中心 center・大きさ side・向き angle（ラジアン）の位置へ
    static func place(_ points: [CGPoint], center: CGPoint, side: Double, angle: Double) -> [CGPoint] {
        let c = cos(angle), s = sin(angle)
        return points.map { p in
            let x = (p.x - 0.5) * side, y = (p.y - 0.5) * side
            return CGPoint(x: center.x + x * c - y * s, y: center.y + x * s + y * c)
        }
    }

    /// 紙（紙飛行機）を描く。下の翼に影を付け、まん中の折り目を引く
    static func draw(_ points: [CGPoint], fold: Double, in context: GraphicsContext, lineWidth: Double) {
        var outline = Path()
        outline.addLines(points)
        outline.closeSubpath()
        context.fill(outline, with: .color(DS.PaperPlane.paper))
        if fold > 0.05 {
            // 下の翼（左・機首・下・左下）は少し暗い
            var wing = Path()
            wing.addLines([points[7], points[2], points[5], points[6]])
            wing.closeSubpath()
            context.fill(wing, with: .color(DS.PaperPlane.paperShade.opacity(Ease.clamp(fold * 1.4))))
            var crease = Path()
            crease.move(to: points[7])
            crease.addLine(to: points[2])
            context.stroke(crease, with: .color(DS.PaperPlane.crease.opacity(Ease.clamp(fold * 1.4))), lineWidth: lineWidth)
        } else {
            // まだ紙のときは、うっすら対角の折り筋
            var crease = Path()
            crease.move(to: points[0])
            crease.addLine(to: points[4])
            context.stroke(crease, with: .color(DS.PaperPlane.crease.opacity(0.5)), lineWidth: lineWidth * 0.7)
        }
        context.stroke(outline, with: .color(DS.PaperPlane.crease.opacity(0.7)),
                       style: StrokeStyle(lineWidth: lineWidth * 0.8, lineJoin: .round))
    }
}

// MARK: - 折りたたまれるチェック

/// progress 0 で白い紙、1 で飛び立ったあとのチェック。アニメーションで 0→1 に動かすと、
/// くしゃっと折りたたまれて紙飛行機になる → 少し沈む → 飛び立つ（ここで消える）→ 点線の丸とチェックが出る。
struct PaperFold: View, Animatable {
    var progress: Double

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let launchAt = DS.PaperPlane.launchAt
            let check = Ease.outBack((progress - launchAt) / (1 - launchAt), overshoot: 2)
            ZStack {
                if progress < launchAt {
                    Canvas { context, canvasSize in
                        Self.drawPaper(progress: progress, in: context, size: canvasSize)
                    }
                } else {
                    Circle()
                        .strokeBorder(DS.PaperPlane.trail.opacity(0.85),
                                      style: StrokeStyle(lineWidth: max(1, size * 0.05), lineCap: .round, dash: [size * 0.04, size * 0.11]))
                        .scaleEffect(0.6 + 0.4 * check)
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.44, weight: .bold))
                        .foregroundStyle(DS.PaperPlane.trail)
                        .scaleEffect(check)
                }
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }

    /// 紙の動き（折る → 沈む）
    static func drawPaper(progress: Double, in context: GraphicsContext, size: CGSize) {
        let side = min(size.width, size.height)
        let foldedAt = DS.PaperPlane.foldedAt, launchAt = DS.PaperPlane.launchAt
        let fold = Ease.smoothstep(0, foldedAt, progress)
        // 折りあがったら、ふわっと沈んで、飛び立つ前に少し持ち上がる
        let dipT = Ease.clamp((progress - foldedAt) / (launchAt - foldedAt))
        let dip = sin(dipT * .pi) * 0.16 - Ease.smoothstep(0.7, 1, dipT) * 0.08
        let angle = (-10 + (-28 + 10) * fold + dip * 30) * .pi / 180
        let scale = 0.66 + (0.92 - 0.66) * fold
        let points = PaperPlaneForm.place(PaperPlaneForm.points(fold: fold),
                                          center: CGPoint(x: size.width / 2, y: size.height / 2 + side * dip),
                                          side: side * scale, angle: angle)
        var c = context
        c.addFilter(.shadow(color: .black.opacity(0.3), radius: side * 0.04, y: side * 0.03))
        PaperPlaneForm.draw(points, fold: fold, in: c, lineWidth: max(0.6, side * 0.025))
    }
}

struct PaperPlaneCheck: View {
    let isCompleted: Bool
    var isAnimated = true

    var body: some View {
        PaperFold(progress: isCompleted ? 1 : 0)
            .animation(isAnimated ? (isCompleted ? .linear(duration: DS.PaperPlane.foldDuration) : .easeOut(duration: 0.3)) : nil,
                       value: isCompleted)
    }
}

// MARK: - 背景の雲（ゆっくり流れる）

struct PaperClouds: View {
    let time: TimeInterval

    private static let dots = AmbientDot.make(count: 7, seed: 0x9A9E7)

    var body: some View {
        Canvas { context, size in
            let travel = size.width + 240
            for dot in Self.dots {
                let distance = (time * 5 * dot.speed + dot.x * travel).truncatingRemainder(dividingBy: travel)
                let x = distance - 120
                let y = dot.y * size.height
                let w = 70 + dot.size * 90
                var c = context
                c.opacity = 0.03 + 0.03 * dot.size
                for (dx, dy, r) in [(-0.3, 0.05, 0.28), (0.0, -0.08, 0.36), (0.32, 0.04, 0.26)] as [(Double, Double, Double)] {
                    let rr = w * r
                    c.fill(Path(ellipseIn: CGRect(x: x + w * dx - rr, y: y + w * dy - rr * 0.7, width: rr * 2, height: rr * 1.4)),
                           with: .color(.white))
                }
            }
        }
    }
}
