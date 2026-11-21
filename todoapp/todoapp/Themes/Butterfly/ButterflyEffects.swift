//
//  ButterflyEffects.swift
//  todoapp
//
//  ちょうちょのテーマの演出。画面全体に重ねた 1 枚の層（ButterflyEffectsLayer）で描く。
//  - flyAway: チェックを外したとき、カードの右端にとまっていたちょうちょが、ひらひらと空へ飛んでいく
//  羽化してカードにとまるまでは、チェック（ButterflyHatch）とカードの上の ButterflyPerch が描く。
//

import SwiftUI
import Observation

@Observable
final class ButterflyEffects {
    fileprivate struct Leave {
        let start: CGPoint
        let palette: ButterflyPalette
        /// 右へ行くか左へ行くか（-1 / 1）
        let drift: Double
        let birth: TimeInterval
    }

    fileprivate private(set) var leaves: [Leave] = []

    var isIdle: Bool { leaves.isEmpty }

    /// とまっていた場所から、ちょうちょが飛んでいく
    func flyAway(from point: CGPoint, palette: ButterflyPalette) {
        leaves.append(Leave(start: point, palette: palette, drift: Bool.random() ? 1 : -1, birth: now))
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(DS.Butterfly.leaveDuration + 0.1))
            guard let self else { return }
            let time = Date.timeIntervalSinceReferenceDate
            leaves.removeAll { time - $0.birth > DS.Butterfly.leaveDuration }
        }
    }

    private var now: TimeInterval { Date.timeIntervalSinceReferenceDate }
}

/// 画面全体に重ねる演出の層（タップは下へ通す）
struct ButterflyEffectsLayer: View {
    let effects: ButterflyEffects

    var body: some View {
        TimelineView(.animation(paused: effects.isIdle)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, _ in
                for leave in effects.leaves {
                    draw(leave, at: time - leave.birth, in: context)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func draw(_ leave: ButterflyEffects.Leave, at t: TimeInterval, in context: GraphicsContext) {
        let duration = DS.Butterfly.leaveDuration
        guard t >= 0, t <= duration else { return }
        let k = t / duration
        // ふわっと浮いてから、ジグザグに上へ遠ざかる
        let rise = 320 * Ease.inCubic(k) + 40 * k
        let x = leave.start.x + leave.drift * (60 * k + sin(t * 6) * 18 * k)
        let y = leave.start.y - rise + sin(t * 11) * 5
        let open = 0.2 + 0.8 * abs(sin(t * 17))
        var c = context
        c.opacity = 1 - Ease.smoothstep(0.65, 1, k)
        ButterflyDrawing.draw(in: c, center: CGPoint(x: x, y: y),
                              side: Double(DS.Butterfly.perchSize) * (1 + 0.25 * sin(k * .pi)),
                              open: open, palette: leave.palette, angle: leave.drift * 0.35 * k + sin(t * 5) * 0.2)
    }
}
