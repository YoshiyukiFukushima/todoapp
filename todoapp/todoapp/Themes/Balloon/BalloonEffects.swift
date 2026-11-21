//
//  BalloonEffects.swift
//  todoapp
//
//  風船のテーマの演出。画面全体に重ねた 1 枚の層（BalloonEffectsLayer）で描く。
//  - pop: 風船が割れた瞬間、ゴムの破片と紙吹雪が飛び散り、ひもがひらりと落ちていく
//  ふくらむ動きそのものは、チェック（BalloonInflate）が描く。
//

import SwiftUI
import Observation

@Observable
final class BalloonEffects {
    fileprivate enum Kind {
        /// ゴムの破片（風船の色）
        case shard(Color)
        /// 紙吹雪（いろいろな色）
        case confetti(Color)
    }

    fileprivate struct Piece {
        let kind: Kind
        let origin: CGPoint
        let velocity: CGVector
        let size: Double
        let spin: Double
        let phase: Double
        let birth: TimeInterval
        let life: TimeInterval
    }

    fileprivate struct Pop {
        let center: CGPoint
        /// 割れたときの風船の大きさ（ぱっと光る輪の大きさ）
        let radius: Double
        let color: BalloonColor
        /// ひもの付け根（結び目）
        let knot: CGPoint
        let stringLength: Double
        let birth: TimeInterval
    }

    fileprivate private(set) var pieces: [Piece] = []
    fileprivate private(set) var pops: [Pop] = []

    var isIdle: Bool { pieces.isEmpty && pops.isEmpty }

    /// チェックの位置で、風船がふくらみきったところで割れる
    func pop(at center: CGPoint, size: CGFloat, color: BalloonColor) {
        let start = now + DS.Balloon.popDelay
        let s = Double(size)
        // 割れる直前の風船のまん中（チェックの少し上）
        let balloonCenter = CGPoint(x: center.x, y: center.y - s * 0.08)
        pops.append(Pop(center: balloonCenter, radius: s * 0.42, color: color,
                        knot: CGPoint(x: center.x, y: center.y + s * 0.36), stringLength: s * 1.5, birth: start))
        for _ in 0..<7 {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = Double.random(in: 110...200)
            pieces.append(Piece(kind: .shard(color.mid), origin: balloonCenter,
                                velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed - 40),
                                size: s * .random(in: 0.16...0.26), spin: .random(in: -14...14), phase: 0,
                                birth: start, life: .random(in: 0.5...0.7)))
        }
        let colors = BalloonColor.all.map(\.mid) + [.white]
        for index in 0..<18 {
            let angle = -Double.pi / 2 + .random(in: -1.5...1.5)
            let speed = Double.random(in: 90...210)
            pieces.append(Piece(kind: .confetti(colors[index % colors.count]), origin: balloonCenter,
                                velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
                                size: .random(in: 3...5), spin: .random(in: -10...10), phase: .random(in: 0...(2 * .pi)),
                                birth: start + .random(in: 0...0.04), life: .random(in: 1.2...1.7)))
        }
        scheduleCleanup()
    }

    private var now: TimeInterval { Date.timeIntervalSinceReferenceDate }

    private func scheduleCleanup() {
        let lastEnd = max(pieces.map { $0.birth + $0.life }.max() ?? now,
                          (pops.map(\.birth).max() ?? now) + BalloonEffectsLayer.stringLife)
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(max(0, lastEnd - Date.timeIntervalSinceReferenceDate) + 0.1))
            guard let self else { return }
            let time = Date.timeIntervalSinceReferenceDate
            pieces.removeAll { $0.birth + $0.life < time }
            pops.removeAll { $0.birth + BalloonEffectsLayer.stringLife < time }
        }
    }
}

/// 画面全体に重ねる演出の層（タップは下へ通す）
struct BalloonEffectsLayer: View {
    let effects: BalloonEffects

    /// ひもが落ちきって消えるまで
    static let stringLife: TimeInterval = 1.5

    var body: some View {
        TimelineView(.animation(paused: effects.isIdle)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, _ in
                for pop in effects.pops {
                    draw(pop, at: time - pop.birth, in: context)
                }
                for piece in effects.pieces {
                    draw(piece, at: time - piece.birth, in: context)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: 割れた瞬間の光と、落ちていくひも

    private func draw(_ pop: BalloonEffects.Pop, at t: TimeInterval, in context: GraphicsContext) {
        guard t >= 0, t <= Self.stringLife else { return }
        // パンッ：一瞬だけ広がる輪
        if t < 0.18 {
            let k = t / 0.18
            let r = pop.radius * (0.8 + 1.0 * k)
            var c = context
            c.opacity = 1 - k
            c.stroke(Path(ellipseIn: CGRect(x: pop.center.x - r, y: pop.center.y - r, width: r * 2, height: r * 2)),
                     with: .color(.white), lineWidth: 2.5 * (1 - k) + 0.5)
        }
        // ひも：ゆらゆら左右に揺れながら、ゆっくり落ちる
        let fall = 50 * t + 70 * t * t
        let sway = sin(t * 5.5) * 9
        let top = CGPoint(x: pop.knot.x + sway, y: pop.knot.y + fall)
        let length = pop.stringLength
        let bend = sin(t * 7 + 1) * length * 0.22
        var string = Path()
        string.move(to: top)
        string.addCurve(to: CGPoint(x: top.x - sway * 0.6, y: top.y + length),
                        control1: CGPoint(x: top.x + bend, y: top.y + length * 0.35),
                        control2: CGPoint(x: top.x - bend, y: top.y + length * 0.7))
        var c = context
        c.opacity = 1 - Ease.smoothstep(Self.stringLife * 0.6, Self.stringLife, t)
        c.stroke(string, with: .color(DS.Balloon.string), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        // ひもに残った結び目
        var knot = Path()
        knot.move(to: CGPoint(x: top.x, y: top.y - 4))
        knot.addLine(to: CGPoint(x: top.x - 3, y: top.y + 1.5))
        knot.addLine(to: CGPoint(x: top.x + 3, y: top.y + 1.5))
        knot.closeSubpath()
        c.fill(knot, with: .color(pop.color.deep))
    }

    // MARK: 破片と紙吹雪

    private func draw(_ piece: BalloonEffects.Piece, at t: TimeInterval, in context: GraphicsContext) {
        guard t >= 0, t <= piece.life else { return }
        var c = context
        switch piece.kind {
        case .shard(let color):
            // 勢いよく飛んで、すぐ落ちる
            let x = piece.origin.x + piece.velocity.dx * t
            let y = piece.origin.y + piece.velocity.dy * t + 520 * t * t
            c.opacity = 1 - Ease.smoothstep(piece.life * 0.55, piece.life, t)
            c.translateBy(x: x, y: y)
            c.rotate(by: .radians(t * piece.spin))
            // ちぎれたゴム（ゆがんだ三日月）
            let s = piece.size
            var shard = Path()
            shard.move(to: CGPoint(x: -s * 0.5, y: 0))
            shard.addQuadCurve(to: CGPoint(x: s * 0.5, y: -s * 0.1), control: CGPoint(x: 0, y: -s * 0.55))
            shard.addQuadCurve(to: CGPoint(x: -s * 0.5, y: 0), control: CGPoint(x: s * 0.05, y: -s * 0.15))
            shard.closeSubpath()
            c.fill(shard, with: .color(color))
        case .confetti(let color):
            // ぱっと散ったあと、空気に止められて、ひらひら落ちる
            let drag = 1 - exp(-3.2 * t)
            let x = piece.origin.x + piece.velocity.dx / 3.2 * drag + sin(t * 6 + piece.phase) * 6
            let y = piece.origin.y + piece.velocity.dy / 3.2 * drag + 55 * t * t
            c.opacity = 1 - Ease.smoothstep(piece.life * 0.65, piece.life, t)
            c.translateBy(x: x, y: y)
            c.rotate(by: .radians(t * piece.spin + piece.phase))
            // 裏返るように幅が変わる
            let flip = abs(cos(t * 9 + piece.phase))
            let w = piece.size * (0.25 + 0.75 * flip), h = piece.size * 1.7
            c.fill(Path(CGRect(x: -w / 2, y: -h / 2, width: w, height: h)), with: .color(color))
        }
    }
}
