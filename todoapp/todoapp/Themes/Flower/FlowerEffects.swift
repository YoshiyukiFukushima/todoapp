//
//  FlowerEffects.swift
//  todoapp
//
//  花びらが舞い落ちる演出。行の外まで落ちるので、画面全体に重ねた 1 枚の層（FlowerEffectsLayer）で描く。
//  - shed: 咲いた花から、花びらが何枚かひらひら落ちる
//  - celebrate: 全部終わったとき、画面の上から花びらが降ってくる
//  咲く動きそのものは、チェックの丸（FlowerBlossom）が描く。
//

import SwiftUI
import Observation

@Observable
final class FlowerEffects {
    fileprivate struct Petal {
        let kind: FlowerKind
        let origin: CGPoint
        /// 落ち始めの横向きの勢い
        let drift: Double
        let fallSpeed: Double
        let sway: Double
        let swaySpeed: Double
        let spin: Double
        let flipSpeed: Double
        let phase: Double
        let size: Double
        let shade: Int
        let birth: TimeInterval
        let life: TimeInterval
    }

    fileprivate private(set) var petals: [Petal] = []

    var isIdle: Bool { petals.isEmpty }

    /// 演出の層の大きさ（＝画面）。降ってくる花びらの幅に使う
    @ObservationIgnored fileprivate var visibleBounds: CGRect = .zero

    /// 咲いた花から、花びらが何枚か舞い落ちる
    func shed(_ kind: FlowerKind, at center: CGPoint, radius: CGFloat) {
        let spec = kind.spec
        let start = now + spec.shedDelay
        let count = Int.random(in: spec.shedCount)
        for index in 0..<count {
            let angle = Double(index) / Double(count) * .pi * 2 + .random(in: -0.5...0.5)
            let distance = Double(radius) * .random(in: 1.0...1.5)
            petals.append(Petal(
                kind: kind,
                origin: CGPoint(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance),
                drift: cos(angle) * .random(in: 12...26),
                fallSpeed: .random(in: 26...44),
                sway: .random(in: 8...16),
                swaySpeed: .random(in: 2.2...3.2),
                spin: .random(in: -1.6...1.6),
                flipSpeed: .random(in: 2.5...4.5),
                phase: .random(in: 0...(.pi * 2)),
                size: Double(radius) * .random(in: 0.7...0.95),
                shade: .random(in: 0..<spec.petalShades.count),
                birth: start + Double(index) * .random(in: 0.08...0.18),
                life: .random(in: 1.8...2.6)
            ))
        }
        scheduleCleanup()
    }

    /// 全部終わったときのご褒美：画面の上から花びらが降ってくる
    func celebrate(_ kind: FlowerKind) {
        let spec = kind.spec
        let delay = spec.shedDelay * 0.6
        let bounds = visibleBounds.isEmpty ? CGRect(x: 0, y: 0, width: 400, height: 860) : visibleBounds
        let start = now + delay
        for _ in 0..<44 {
            let fallSpeed = Double.random(in: 90...170)
            petals.append(Petal(
                kind: kind,
                origin: CGPoint(x: .random(in: bounds.minX...bounds.maxX), y: bounds.minY - .random(in: 10...60)),
                drift: .random(in: -18...18),
                fallSpeed: fallSpeed,
                sway: .random(in: 14...34),
                swaySpeed: .random(in: 1.4...2.6),
                spin: .random(in: -2.2...2.2),
                flipSpeed: .random(in: 2...4),
                phase: .random(in: 0...(.pi * 2)),
                size: .random(in: spec.fallingSize),
                shade: .random(in: 0..<spec.petalShades.count),
                birth: start + .random(in: 0...DS.Flower.celebrationSpread),
                // 画面の下まで落ちきる時間
                life: (bounds.height + 80) / fallSpeed
            ))
        }
        scheduleCleanup()
    }

    private var now: TimeInterval { Date.timeIntervalSinceReferenceDate }

    private func scheduleCleanup() {
        let lastEnd = petals.map { $0.birth + $0.life }.max() ?? now
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(max(0, lastEnd - Date.timeIntervalSinceReferenceDate) + 0.1))
            guard let self else { return }
            let time = Date.timeIntervalSinceReferenceDate
            petals.removeAll { $0.birth + $0.life < time }
        }
    }
}

/// 画面全体に重ねる演出の層（タップは下へ通す）
struct FlowerEffectsLayer: View {
    let effects: FlowerEffects

    var body: some View {
        TimelineView(.animation(paused: effects.isIdle)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, _ in
                for petal in effects.petals {
                    draw(petal, at: time - petal.birth, in: &context)
                }
            }
        }
        .ignoresSafeArea()
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { effects.visibleBounds = $0 }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func draw(_ petal: FlowerEffects.Petal, at t: TimeInterval, in context: inout GraphicsContext) {
        guard t >= 0, t <= petal.life else { return }
        // 初めは横へふわっと流れ、だんだん左右に揺れながら落ちる
        let driftEased = 1 - exp(-t * 2.5)
        let x = petal.origin.x + petal.drift * driftEased + sin(t * petal.swaySpeed + petal.phase) * petal.sway * min(t * 1.5, 1)
        let y = petal.origin.y + petal.fallSpeed * t + 6 * t * t
        let fadeIn = min(t / 0.15, 1)
        let fadeOut = min(max((petal.life - t) / min(0.6, petal.life * 0.35), 0), 1)
        let spec = petal.kind.spec
        FlowerDrawing.drawPetal(
            in: &context, spec: spec, center: CGPoint(x: x, y: y), size: petal.size,
            angle: .radians(petal.phase + t * petal.spin),
            flip: cos(t * petal.flipSpeed + petal.phase),
            color: spec.petalShades[petal.shade % spec.petalShades.count],
            opacity: 0.95 * fadeIn * fadeOut)
    }
}
