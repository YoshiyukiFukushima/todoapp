//
//  PaperPlaneEffects.swift
//  todoapp
//
//  紙飛行機のテーマの演出。画面全体に重ねた 1 枚の層（PaperPlaneEffectsLayer）で描く。
//  - launch: チェックの中で折りあがった紙飛行機が、点線の軌跡を残して、ぐいっと右上の空へ飛んでいく
//  紙が折りたたまれる動きそのものは、チェック（PaperFold）が描く。
//

import SwiftUI
import Observation

@Observable
final class PaperPlaneEffects {
    fileprivate struct Flight {
        let start: CGPoint
        /// チェックの大きさ（紙飛行機の大きさ）
        let size: Double
        let birth: TimeInterval
    }

    fileprivate private(set) var flights: [Flight] = []

    var isIdle: Bool { flights.isEmpty }

    @ObservationIgnored fileprivate var visibleBounds: CGRect = .zero

    /// 折りあがって沈んだあと、チェックの位置から飛び立つ
    func launch(from center: CGPoint, size: CGFloat) {
        flights.append(Flight(start: center, size: Double(size), birth: now + DS.PaperPlane.launchDelay))
        let life = DS.PaperPlane.launchDelay + DS.PaperPlane.flightDuration + DS.PaperPlane.trailFade
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(life + 0.1))
            guard let self else { return }
            let time = Date.timeIntervalSinceReferenceDate
            flights.removeAll { time - $0.birth > DS.PaperPlane.flightDuration + DS.PaperPlane.trailFade }
        }
    }

    private var now: TimeInterval { Date.timeIntervalSinceReferenceDate }
}

/// 画面全体に重ねる演出の層（タップは下へ通す）
struct PaperPlaneEffectsLayer: View {
    let effects: PaperPlaneEffects

    var body: some View {
        TimelineView(.animation(paused: effects.isIdle)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let bounds = effects.visibleBounds.isEmpty ? CGRect(origin: .zero, size: size) : effects.visibleBounds
                for flight in effects.flights {
                    draw(flight, at: time - flight.birth, bounds: bounds, in: context)
                }
            }
        }
        .ignoresSafeArea()
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { effects.visibleBounds = $0 }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// 飛ぶ道すじ（3 次ベジェ）。チェックの中で向いていた右斜め上へ出て、右上の空へぐいっと昇る
    private func route(_ flight: PaperPlaneEffects.Flight, bounds: CGRect) -> [CGPoint] {
        let s = flight.size, start = flight.start
        let end = CGPoint(x: bounds.maxX + 80, y: max(bounds.minY - 80, start.y - 520))
        return [start,
                CGPoint(x: start.x + s * 2.0, y: start.y - s * 1.15),
                CGPoint(x: start.x + (end.x - start.x) * 0.45, y: start.y - s * 1.2),
                end]
    }

    private func point(on c: [CGPoint], at u: Double) -> CGPoint {
        let v = 1 - u
        let a = v * v * v, b = 3 * v * v * u, d = 3 * v * u * u, e = u * u * u
        return CGPoint(x: a * c[0].x + b * c[1].x + d * c[2].x + e * c[3].x,
                       y: a * c[0].y + b * c[1].y + d * c[2].y + e * c[3].y)
    }

    /// 飛んだ距離（はじめはゆっくり、だんだん速く）
    private func travel(_ t: TimeInterval) -> Double {
        let x = Ease.clamp(t / DS.PaperPlane.flightDuration)
        return 0.25 * x + 0.75 * x * x
    }

    private func draw(_ flight: PaperPlaneEffects.Flight, at t: TimeInterval, bounds: CGRect, in context: GraphicsContext) {
        let duration = DS.PaperPlane.flightDuration
        guard t >= 0, t <= duration + DS.PaperPlane.trailFade else { return }
        let curve = route(flight, bounds: bounds)
        let u = travel(t)

        // 点線の軌跡（通ったところに残り、飛び去ったあとに消える）
        var trail = Path()
        let steps = 40
        trail.move(to: curve[0])
        for i in 1...steps {
            trail.addLine(to: point(on: curve, at: u * Double(i) / Double(steps)))
        }
        var tc = context
        tc.opacity = 0.75 * (1 - Ease.smoothstep(duration * 0.75, duration + DS.PaperPlane.trailFade, t))
        tc.stroke(trail, with: .color(DS.PaperPlane.trail),
                  style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [2, 6]))

        guard t <= duration else { return }
        // 紙飛行機（進む向きを向き、近づくように少し大きくなる）
        let here = point(on: curve, at: u)
        let ahead = point(on: curve, at: min(u + 0.01, 1))
        let angle = atan2(ahead.y - here.y, ahead.x - here.x)
        let side = flight.size * 0.92 * (1 + 0.5 * u)
        let points = PaperPlaneForm.place(PaperPlaneForm.plane, center: here, side: side, angle: angle)
        var pc = context
        pc.addFilter(.shadow(color: .black.opacity(0.3), radius: 3, y: 3))
        PaperPlaneForm.draw(points, fold: 1, in: pc, lineWidth: max(0.6, side * 0.025))
    }
}
