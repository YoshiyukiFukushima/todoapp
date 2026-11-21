//
//  WaterEffects.swift
//  todoapp
//
//  しずくの演出。行の外から落ちてくるので、画面全体に重ねた 1 枚の層（WaterEffectsLayer）で描く。
//  - drop: しずくが上から落ちてボタンに当たり、波紋が広がって、小さなしぶきが跳ねる
//  - celebrate: 全部終わったとき、画面に雨が降り、あちこちに波紋が広がる
//  当たったあとの水玉のぷるぷるした揺れと、カードにたまる水は、行の側（CheckButton・WaterPool）が描く。
//

import SwiftUI
import Observation

@Observable
final class WaterEffects {
    fileprivate struct Drop {
        /// 当たる場所
        let target: CGPoint
        let radius: Double
        /// どれだけ上から落ちてくるか
        let height: Double
        let birth: TimeInterval
        let fall: TimeInterval
        /// 当たったところに波紋を出すか
        let ripples: Int
        let rippleRadius: Double
    }

    fileprivate struct Splash {
        let origin: CGPoint
        let velocity: CGVector
        let radius: Double
        let birth: TimeInterval
        let life: TimeInterval
    }

    fileprivate private(set) var drops: [Drop] = []
    fileprivate private(set) var splashes: [Splash] = []

    var isIdle: Bool { drops.isEmpty && splashes.isEmpty }

    @ObservationIgnored fileprivate var visibleBounds: CGRect = .zero

    /// しずくが落ちてきて、center に当たる
    func drop(at center: CGPoint, radius: CGFloat) {
        let start = now
        drops.append(Drop(target: center, radius: Double(radius) * 0.42, height: DS.Water.fallHeight,
                          birth: start, fall: DS.Water.fallDuration, ripples: 2, rippleRadius: Double(radius)))
        addSplashes(at: center, radius: Double(radius), time: start + DS.Water.fallDuration)
        scheduleCleanup()
    }

    /// 全部終わったときのご褒美：雨が降って、あちこちに波紋が広がる
    func celebrate(delay: TimeInterval = DS.Water.fallDuration + 0.4) {
        let bounds = visibleBounds.isEmpty ? CGRect(x: 0, y: 0, width: 400, height: 860) : visibleBounds
        let start = now + delay
        for _ in 0..<34 {
            let target = CGPoint(x: .random(in: bounds.minX + 10...bounds.maxX - 10),
                                 y: .random(in: bounds.minY + bounds.height * 0.25...bounds.maxY - 30))
            let height = Double(target.y - bounds.minY) + .random(in: 20...60)
            drops.append(Drop(target: target, radius: .random(in: 3...5.5), height: height,
                              birth: start + .random(in: 0...DS.Water.rainSpread),
                              fall: height / .random(in: 700...950), ripples: 1, rippleRadius: .random(in: 12...22)))
        }
        scheduleCleanup()
    }

    private func addSplashes(at center: CGPoint, radius: Double, time: TimeInterval) {
        for index in 0..<4 {
            let side: Double = index.isMultiple(of: 2) ? -1 : 1
            splashes.append(Splash(
                origin: CGPoint(x: center.x, y: center.y - radius * 0.5),
                velocity: CGVector(dx: side * .random(in: 25...60), dy: -.random(in: 70...120)),
                radius: .random(in: 1.4...2.4),
                birth: time,
                life: .random(in: 0.45...0.6)
            ))
        }
    }

    private var now: TimeInterval { Date.timeIntervalSinceReferenceDate }

    private func scheduleCleanup() {
        let lastDrop = drops.map { $0.birth + $0.fall + DS.Water.rippleDuration * 1.4 }.max() ?? now
        let lastSplash = splashes.map { $0.birth + $0.life }.max() ?? now
        let lastEnd = max(lastDrop, lastSplash)
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(max(0, lastEnd - Date.timeIntervalSinceReferenceDate) + 0.1))
            guard let self else { return }
            let time = Date.timeIntervalSinceReferenceDate
            drops.removeAll { $0.birth + $0.fall + DS.Water.rippleDuration * 1.4 < time }
            splashes.removeAll { $0.birth + $0.life < time }
        }
    }
}

/// 画面全体に重ねる演出の層（タップは下へ通す）
struct WaterEffectsLayer: View {
    let effects: WaterEffects

    var body: some View {
        TimelineView(.animation(paused: effects.isIdle)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, _ in
                for drop in effects.drops {
                    draw(drop, at: time - drop.birth, in: &context)
                }
                for splash in effects.splashes {
                    draw(splash, at: time - splash.birth, in: &context)
                }
            }
        }
        .ignoresSafeArea()
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { effects.visibleBounds = $0 }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func draw(_ drop: WaterEffects.Drop, at t: TimeInterval, in context: inout GraphicsContext) {
        guard t >= 0 else { return }
        if t < drop.fall {
            // だんだん速く落ちる。速いほど縦に伸びる
            let p = t / drop.fall
            let y = drop.target.y - drop.height * (1 - p * p)
            WaterDrawing.drawDrop(in: &context, center: CGPoint(x: drop.target.x, y: y), radius: drop.radius,
                                  stretch: 1 + 0.25 * p, opacity: min(t / 0.06, 1))
            return
        }
        // 当たったあと：波紋が少しずつずれて広がる
        let after = t - drop.fall
        for index in 0..<drop.ripples {
            let rt = after - Double(index) * 0.14
            guard rt >= 0, rt <= DS.Water.rippleDuration else { continue }
            let p = rt / DS.Water.rippleDuration
            let eased = 1 - pow(1 - p, 2.4)
            let radius = drop.rippleRadius * (0.7 + 1.9 * eased)
            WaterDrawing.drawRipple(in: &context, center: drop.target, radius: radius, opacity: 1 - p)
        }
    }

    private func draw(_ splash: WaterEffects.Splash, at t: TimeInterval, in context: inout GraphicsContext) {
        guard t >= 0, t <= splash.life else { return }
        let gravity = 420.0
        let x = splash.origin.x + splash.velocity.dx * t
        let y = splash.origin.y + splash.velocity.dy * t + 0.5 * gravity * t * t
        let fade = 1 - t / splash.life
        WaterDrawing.drawDrop(in: &context, center: CGPoint(x: x, y: y), radius: splash.radius, opacity: fade)
    }
}
