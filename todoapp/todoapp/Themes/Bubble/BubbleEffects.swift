//
//  BubbleEffects.swift
//  todoapp
//
//  泡がはじける演出。行の外まで泡が飛ぶので、画面全体に重ねた 1 枚の層（BubbleEffectsLayer）で描く。
//  - pop: チェックした泡がはじけ、輪が広がり、小さな泡が飛び散ってから上へ昇る
//  - celebrate: 全部終わったとき、見えているカードから順番に泡があふれ出す
//

import SwiftUI
import Observation

@Observable
final class BubbleEffects {
    fileprivate struct Particle {
        let origin: CGPoint
        /// 飛び散る向き × 距離
        let burst: CGVector
        let radius: Double
        let riseSpeed: Double
        let wobble: Double
        let phase: Double
        let birth: TimeInterval
        let life: TimeInterval
    }

    fileprivate struct Ring {
        let center: CGPoint
        let radius: Double
        let birth: TimeInterval
    }

    fileprivate private(set) var particles: [Particle] = []
    fileprivate private(set) var rings: [Ring] = []

    var isIdle: Bool { particles.isEmpty && rings.isEmpty }

    /// タスクカードの画面上の位置（全部終わったときの演出に使う）。スクロールのたびに変わるので、描き直しの対象にしない
    @ObservationIgnored private var cardFrames: [UUID: CGRect] = [:]

    /// 演出の層の大きさ（＝画面）。見えているカードだけを選ぶのに使う
    @ObservationIgnored fileprivate var visibleBounds: CGRect = .zero

    func updateCardFrame(_ frame: CGRect, for id: UUID) { cardFrames[id] = frame }
    func removeCardFrame(for id: UUID) { cardFrames[id] = nil }

    /// チェックした泡がはじける
    func pop(at center: CGPoint, radius: CGFloat, delay: TimeInterval = DS.Bubble.popDelay) {
        let start = now + delay
        rings.append(Ring(center: center, radius: radius, birth: start))
        let count = 9
        for index in 0..<count {
            let angle = Double(index) / Double(count) * .pi * 2 + .random(in: -0.25...0.25)
            let distance = Double(radius) * .random(in: 1.4...2.4)
            particles.append(Particle(
                origin: center,
                burst: CGVector(dx: cos(angle) * distance, dy: sin(angle) * distance),
                radius: .random(in: 2...5.5),
                riseSpeed: .random(in: 45...90),
                wobble: .random(in: 3...8),
                phase: .random(in: 0...(.pi * 2)),
                birth: start,
                life: .random(in: 1.4...2.2)
            ))
        }
        scheduleCleanup()
    }

    /// 全部終わったときのご褒美：見えているカードから上から順に泡があふれ出す
    func celebrate(delay: TimeInterval = 0.45) {
        let frames = cardFrames.values
            .filter { visibleBounds.isEmpty || $0.intersects(visibleBounds) }
            .sorted { $0.minY < $1.minY }
        let start = now + delay
        for (index, frame) in frames.enumerated() {
            let cardStart = start + Double(index) * DS.Bubble.celebrationStagger
            rings.append(Ring(center: CGPoint(x: frame.minX + 34, y: frame.midY), radius: DS.Size.bubbleCheckbox / 2, birth: cardStart))
            for _ in 0..<14 {
                let x = Double.random(in: frame.minX + 16...max(frame.minX + 17, frame.maxX - 16))
                let y = Double.random(in: frame.minY + 8...max(frame.minY + 9, frame.maxY - 8))
                particles.append(Particle(
                    origin: CGPoint(x: x, y: y),
                    burst: CGVector(dx: .random(in: -10...10), dy: .random(in: -14...(-2))),
                    radius: .random(in: 2.5...9),
                    riseSpeed: .random(in: 60...130),
                    wobble: .random(in: 4...10),
                    phase: .random(in: 0...(.pi * 2)),
                    birth: cardStart + .random(in: 0...0.35),
                    life: .random(in: 2.0...3.0)
                ))
            }
        }
        scheduleCleanup()
    }

    private var now: TimeInterval { Date.timeIntervalSinceReferenceDate }

    private func scheduleCleanup() {
        let lastEnd = particles.map { $0.birth + $0.life }.max() ?? now
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(max(0, lastEnd - Date.timeIntervalSinceReferenceDate) + 0.1))
            guard let self else { return }
            let time = Date.timeIntervalSinceReferenceDate
            particles.removeAll { $0.birth + $0.life < time }
            rings.removeAll { $0.birth + BubbleEffectsLayer.ringDuration < time }
        }
    }
}

/// 画面全体に重ねる演出の層（タップは下へ通す）
struct BubbleEffectsLayer: View {
    static let ringDuration: TimeInterval = 0.45
    /// 飛び散る時間（そのあと昇る）
    private static let burstDuration: TimeInterval = 0.35

    let effects: BubbleEffects

    var body: some View {
        TimelineView(.animation(paused: effects.isIdle)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, _ in
                for ring in effects.rings {
                    drawRing(ring, at: time - ring.birth, in: &context)
                }
                for particle in effects.particles {
                    drawParticle(particle, at: time - particle.birth, in: &context)
                }
            }
        }
        .ignoresSafeArea()
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { effects.visibleBounds = $0 }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func drawRing(_ ring: BubbleEffects.Ring, at t: TimeInterval, in context: inout GraphicsContext) {
        guard t >= 0, t <= Self.ringDuration else { return }
        let p = t / Self.ringDuration
        let eased = 1 - pow(1 - p, 3)
        let r = ring.radius * (1 + 1.6 * eased)
        let rect = CGRect(x: ring.center.x - r, y: ring.center.y - r, width: r * 2, height: r * 2)
        context.stroke(Circle().path(in: rect),
                       with: .color(DS.Bubble.rim.opacity(0.9 * (1 - p))),
                       lineWidth: 2.4 * (1 - p) + 0.4)
    }

    private func drawParticle(_ particle: BubbleEffects.Particle, at t: TimeInterval, in context: inout GraphicsContext) {
        guard t >= 0, t <= particle.life else { return }
        let burstP = min(t / Self.burstDuration, 1)
        let burstEased = 1 - pow(1 - burstP, 3)
        // 飛び散りが落ち着いてきたら、ふわふわ揺れながら昇る
        let riseT = max(0, t - Self.burstDuration * 0.6)
        let x = particle.origin.x + particle.burst.dx * burstEased + sin(riseT * 4 + particle.phase) * particle.wobble * min(riseT * 2, 1)
        let y = particle.origin.y + particle.burst.dy * burstEased - particle.riseSpeed * riseT - 18 * riseT * riseT
        let fadeIn = min(t / 0.08, 1)
        let fadeOut = min(max((particle.life - t) / (particle.life * 0.4), 0), 1)
        let radius = particle.radius * (0.6 + 0.4 * burstEased) * (1 + 0.12 * riseT)
        BubbleDrawing.draw(in: &context, center: CGPoint(x: x, y: y), radius: radius, opacity: fadeIn * fadeOut)
    }
}
