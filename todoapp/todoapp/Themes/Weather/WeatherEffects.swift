//
//  WeatherEffects.swift
//  todoapp
//
//  くもりのち晴れのテーマの演出。カードのうしろの空に置いた 1 枚の層（WeatherEffectsLayer）で描く。
//  - celebrate: 全部終えたとき、右上から大きな太陽がのぼり、空に虹がかかる。しばらく出ていて、ふっと消える
//    カードのうしろの空に描くので、文字や設定ボタンをふさがない
//  雲が晴れて太陽が出る動きそのものは、チェック（WeatherClear）が描く。
//

import SwiftUI
import Observation

@Observable
final class WeatherEffects {
    fileprivate struct Clearing {
        let birth: TimeInterval
        var end: TimeInterval { birth + WeatherEffectsLayer.riseDuration + DS.Weather.celebrationHold + WeatherEffectsLayer.fadeDuration }
    }

    fileprivate private(set) var clearings: [Clearing] = []

    var isIdle: Bool { clearings.isEmpty }

    /// 全部終えたときのご褒美：大きな太陽と虹
    func celebrate() {
        // 最後のチェックの太陽が出るのを待ってから
        let clearing = Clearing(birth: Date.timeIntervalSinceReferenceDate + DS.Weather.clearDuration * 0.6)
        clearings = [clearing]
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(max(0, clearing.end - Date.timeIntervalSinceReferenceDate) + 0.1))
            guard let self else { return }
            let time = Date.timeIntervalSinceReferenceDate
            clearings.removeAll { $0.end < time }
        }
    }
}

/// 空に出す演出の層（タップは下へ通す）。カードのうしろ、背景のすぐ上に置く（ContentView）
struct WeatherEffectsLayer: View {
    let effects: WeatherEffects

    static let riseDuration: TimeInterval = 1.4
    static let fadeDuration: TimeInterval = 1.0

    var body: some View {
        TimelineView(.animation(paused: effects.isIdle)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                for clearing in effects.clearings {
                    draw(at: time - clearing.birth, size: size, in: context)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func draw(at t: TimeInterval, size: CGSize, in context: GraphicsContext) {
        guard t >= 0 else { return }
        let rise = Self.riseDuration
        let fadeStart = rise + DS.Weather.celebrationHold
        let fade = 1 - Ease.smoothstep(fadeStart, fadeStart + Self.fadeDuration, t)
        guard fade > 0 else { return }

        // 虹：左下から右下へ、1 本ずつ追いかけるようにかかる（ガラスのカード越しに見える）
        var bow = context
        bow.opacity = 0.6 * fade
        let bowCenter = CGPoint(x: size.width / 2, y: size.height * 0.92)
        let outer = size.width * 0.78
        let band = size.width * 0.045
        for (index, color) in DS.Weather.rainbow.enumerated() {
            let p = Ease.outCubic((t - Double(index) * 0.06) / (rise * 0.9))
            guard p > 0 else { continue }
            let r = outer - Double(index) * band
            var arc = Path()
            arc.addArc(center: bowCenter, radius: r, startAngle: .degrees(180), endAngle: .degrees(180 + 180 * p), clockwise: false)
            bow.stroke(arc, with: .color(color), style: StrokeStyle(lineWidth: band * 1.05, lineCap: .butt))
        }

        // 大きな太陽：右上の外から、ゆっくり光を回しながら出てくる
        var sun = context
        sun.opacity = fade
        let come = Ease.outBack(t / rise, overshoot: 1.3)
        let radius = size.width * 0.12
        // 顔が設定ボタンに隠れないよう、ボタンより少し上に置く
        let center = CGPoint(x: size.width - radius * 0.9 + radius * 2.4 * (1 - come),
                             y: radius * 1.05 - radius * 2.4 * (1 - come))
        WeatherDrawing.drawSun(in: sun, center: center, radius: radius,
                               rays: Ease.clamp((t - 0.4) / 0.8), face: Ease.outBack((t - 0.9) / 0.4, overshoot: 2),
                               spin: t * 0.25, rayCount: 10)
    }
}
