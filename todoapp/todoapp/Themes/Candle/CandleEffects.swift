//
//  CandleEffects.swift
//  todoapp
//
//  火を消したあとの演出。煙は行の外まで昇るので、画面全体に重ねた 1 枚の層（CandleEffectsLayer）で描く。
//  - snuff: 芯が一瞬赤く残り、煙がゆらぎながら昇る
//  火が横に吹かれて消える動きは、チェックのろうそく（CandleFace）が描く。
//

import SwiftUI
import Observation

@Observable
final class CandleEffects {
    fileprivate struct Ember {
        let center: CGPoint
        let birth: TimeInterval
    }

    fileprivate struct Puff {
        let origin: CGPoint
        let birth: TimeInterval
        let life: TimeInterval
        let phase: Double
        let drift: Double
    }

    fileprivate private(set) var embers: [Ember] = []
    fileprivate private(set) var puffs: [Puff] = []

    var isIdle: Bool { embers.isEmpty && puffs.isEmpty }

    static let emberLife: TimeInterval = 0.8

    /// 火を消した芯から、赤い残り火と煙
    func snuff(wick: CGPoint) {
        let start = now + DS.Candle.snuffDuration * 0.6
        embers.append(Ember(center: wick, birth: start))
        // 細い煙を、少しずつずらした粒の列で描く
        let drift = Double.random(in: -6...6)
        let phase = Double.random(in: 0...(.pi * 2))
        for index in 0..<22 {
            puffs.append(Puff(origin: wick, birth: start + 0.08 + Double(index) * 0.045,
                              life: 1.6, phase: phase, drift: drift))
        }
        scheduleCleanup()
    }

    private var now: TimeInterval { Date.timeIntervalSinceReferenceDate }

    private func scheduleCleanup() {
        let lastEnd = max(puffs.map { $0.birth + $0.life }.max() ?? now,
                          embers.map { $0.birth + Self.emberLife }.max() ?? now)
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(max(0, lastEnd - Date.timeIntervalSinceReferenceDate) + 0.1))
            guard let self else { return }
            let time = Date.timeIntervalSinceReferenceDate
            puffs.removeAll { $0.birth + $0.life < time }
            embers.removeAll { $0.birth + Self.emberLife < time }
        }
    }
}

/// 画面全体に重ねる演出の層（タップは下へ通す）
struct CandleEffectsLayer: View {
    let effects: CandleEffects

    var body: some View {
        TimelineView(.animation(paused: effects.isIdle)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, _ in
                var smoke = context
                smoke.addFilter(.blur(radius: 1.6))
                for puff in effects.puffs {
                    draw(puff, at: time - puff.birth, in: &smoke)
                }
                for ember in effects.embers {
                    draw(ember, at: time - ember.birth, in: &context)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// 煙：昇るほど広がり、左右にゆらいで、薄くなって消える
    private func draw(_ puff: CandleEffects.Puff, at t: TimeInterval, in context: inout GraphicsContext) {
        guard t >= 0, t <= puff.life else { return }
        let p = t / puff.life
        let rise = 46 * t + 8 * t * t
        let sway = sin(t * 3.4 + puff.phase + rise * 0.05) * (2 + 10 * p) + puff.drift * p
        let center = CGPoint(x: puff.origin.x + sway, y: puff.origin.y - rise)
        let radius = 1.4 + 5.5 * p
        let opacity = 0.32 * min(t / 0.12, 1) * (1 - p)
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Circle().path(in: rect), with: .color(DS.Candle.smoke.opacity(opacity)))
    }

    /// 残り火：芯の先が一瞬赤く光って、すっと消える
    private func draw(_ ember: CandleEffects.Ember, at t: TimeInterval, in context: inout GraphicsContext) {
        let life = CandleEffects.emberLife
        guard t >= 0, t <= life else { return }
        let fade = 1 - t / life
        let glow = CGRect(x: ember.center.x - 6, y: ember.center.y - 6, width: 12, height: 12)
        context.fill(Circle().path(in: glow), with: .radialGradient(
            Gradient(colors: [DS.Candle.ember.opacity(0.75 * fade), DS.Candle.ember.opacity(0)]),
            center: ember.center, startRadius: 0, endRadius: 6))
        let core = CGRect(x: ember.center.x - 1.6, y: ember.center.y - 1.6, width: 3.2, height: 3.2)
        context.fill(Circle().path(in: core), with: .color(DS.Candle.flameMid.opacity(fade)))
    }
}
