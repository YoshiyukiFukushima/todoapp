//
//  ChickEffects.swift
//  todoapp
//
//  ひよこのテーマの演出。画面全体に重ねた 1 枚の層（ChickEffectsLayer）で描く。
//  - hatch: 殻が割れたとき、小さなかけらと光がぱっと散る
//  卵が揺れて割れる動きそのものは、チェック（ChickHatch）が描く。
//

import SwiftUI
import Observation

@Observable
final class ChickEffects {
    fileprivate struct Crumb {
        let origin: CGPoint
        let velocity: CGVector
        let size: Double
        let spin: Double
        let isSparkle: Bool
        let birth: TimeInterval
        let life: TimeInterval
    }

    fileprivate private(set) var crumbs: [Crumb] = []

    var isIdle: Bool { crumbs.isEmpty }

    /// 殻が割れたところから、かけらと光が散る
    func hatch(at center: CGPoint, size: CGFloat) {
        let start = now + DS.Chick.hatchDuration * DS.Chick.splitAt
        let crackPoint = CGPoint(x: center.x, y: center.y)
        for index in 0..<9 {
            let isSparkle = index >= 4
            let angle = -Double.pi / 2 + .random(in: -1.3...1.3)
            let speed = Double.random(in: 40...90)
            crumbs.append(Crumb(
                origin: crackPoint,
                velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
                size: isSparkle ? .random(in: 2...3.5) : Double(size) * .random(in: 0.08...0.13),
                spin: .random(in: -8...8),
                isSparkle: isSparkle,
                birth: start + .random(in: 0...0.06),
                life: .random(in: 0.6...0.9)))
        }
        scheduleCleanup()
    }

    private var now: TimeInterval { Date.timeIntervalSinceReferenceDate }

    private func scheduleCleanup() {
        let lastEnd = crumbs.map { $0.birth + $0.life }.max() ?? now
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(max(0, lastEnd - Date.timeIntervalSinceReferenceDate) + 0.1))
            guard let self else { return }
            let time = Date.timeIntervalSinceReferenceDate
            crumbs.removeAll { $0.birth + $0.life < time }
        }
    }
}

/// 画面全体に重ねる演出の層（タップは下へ通す）
struct ChickEffectsLayer: View {
    let effects: ChickEffects

    var body: some View {
        TimelineView(.animation(paused: effects.isIdle)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, _ in
                for crumb in effects.crumbs {
                    draw(crumb, at: time - crumb.birth, in: context)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func draw(_ crumb: ChickEffects.Crumb, at t: TimeInterval, in context: GraphicsContext) {
        guard t >= 0, t <= crumb.life else { return }
        let x = crumb.origin.x + crumb.velocity.dx * t
        let y = crumb.origin.y + crumb.velocity.dy * t + 160 * t * t
        let fade = 1 - max(0, (t - crumb.life * 0.5) / (crumb.life * 0.5))
        var c = context
        c.opacity = fade
        c.translateBy(x: x, y: y)
        if crumb.isSparkle {
            // 4 方向にとがった小さな光
            let r = crumb.size * (1 + 0.3 * sin(t * 30))
            var star = Path()
            star.move(to: CGPoint(x: 0, y: -r * 2))
            star.addQuadCurve(to: CGPoint(x: r * 2, y: 0), control: .zero)
            star.addQuadCurve(to: CGPoint(x: 0, y: r * 2), control: .zero)
            star.addQuadCurve(to: CGPoint(x: -r * 2, y: 0), control: .zero)
            star.addQuadCurve(to: CGPoint(x: 0, y: -r * 2), control: .zero)
            c.fill(star, with: .color(DS.Chick.bodyLight))
        } else {
            c.rotate(by: .radians(t * crumb.spin))
            let s = crumb.size
            var shard = Path()
            shard.move(to: CGPoint(x: -s, y: s * 0.6))
            shard.addLine(to: CGPoint(x: -s * 0.2, y: -s))
            shard.addLine(to: CGPoint(x: s, y: s * 0.4))
            shard.closeSubpath()
            c.fill(shard, with: .color(DS.Chick.shellMid))
            c.stroke(shard, with: .color(DS.Chick.shellLine), lineWidth: 0.6)
        }
    }
}
