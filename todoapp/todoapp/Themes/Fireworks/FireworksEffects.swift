//
//  FireworksEffects.swift
//  todoapp
//
//  花火のテーマの演出。画面全体に重ねた 1 枚の層（FireworksEffectsLayer）で描く。
//  - burst: チェックした玉から、光の筋がまっすぐ放射状に広がる
//  - celebrate: 全部終わったとき、画面の下から次々に打ち上がって、夜空に大きく開く
//

import SwiftUI
import Observation

@Observable
final class FireworksEffects {
    fileprivate struct Shell {
        /// 打ち上げる場所（nil ならその場で開く）
        let launch: CGPoint?
        let center: CGPoint
        let radius: Double
        let rays: Int
        let rotation: Double
        let color: FireworkColor
        /// 打ち上げ始め
        let birth: TimeInterval
        /// 上がるのにかかる時間（その場で開くなら 0）
        let rise: TimeInterval
        let duration: TimeInterval
        let lineWidth: Double
        /// 開いたあと、ゆっくり下がる
        let droop: Double

        var end: TimeInterval { birth + rise + duration }
    }

    fileprivate private(set) var shells: [Shell] = []

    var isIdle: Bool { shells.isEmpty }

    @ObservationIgnored fileprivate var visibleBounds: CGRect = .zero

    /// チェックした玉から花火が開く
    func burst(at center: CGPoint, radius: CGFloat, color: FireworkColor) {
        shells.append(Shell(launch: nil, center: center, radius: Double(radius) * 3.4, rays: 20,
                            rotation: .random(in: 0...(.pi * 2)), color: color,
                            birth: now + DS.Fireworks.igniteDelay, rise: 0,
                            duration: DS.Fireworks.burstDuration, lineWidth: 1.8, droop: 0))
        scheduleCleanup()
    }

    /// 全部終わったときのご褒美：たくさん打ち上げる
    func celebrate() {
        let bounds = visibleBounds.isEmpty ? CGRect(x: 0, y: 0, width: 400, height: 860) : visibleBounds
        let start = now + 0.35
        let count = 18
        for index in 0..<count {
            // だんだん間隔をつめて、最後はいっせいに
            let progress = Double(index) / Double(count - 1)
            let launchTime = DS.Fireworks.celebrationSpread * (1 - pow(1 - progress, 1.6)) * 0.85
                + (index >= count - 4 ? 0.1 : .random(in: 0...0.15))
            let x = Double.random(in: (bounds.minX + bounds.width * 0.12)...(bounds.maxX - bounds.width * 0.12))
            let apex = CGPoint(x: x + .random(in: -30...30),
                               y: .random(in: (bounds.minY + bounds.height * 0.12)...(bounds.minY + bounds.height * 0.5)))
            let isBig = index >= count - 4 || Bool.random()
            shells.append(Shell(
                launch: CGPoint(x: x, y: bounds.maxY + 10),
                center: apex,
                radius: isBig ? .random(in: 110...150) : .random(in: 65...100),
                rays: isBig ? 36 : 26,
                rotation: .random(in: 0...(.pi * 2)),
                color: FireworkColor.all.randomElement()!,
                birth: start + launchTime,
                rise: .random(in: 0.7...1.0),
                duration: isBig ? 2.3 : 1.9,
                lineWidth: isBig ? 2.4 : 2,
                droop: .random(in: 8...16)))
        }
        scheduleCleanup()
    }

    private var now: TimeInterval { Date.timeIntervalSinceReferenceDate }

    private func scheduleCleanup() {
        let lastEnd = shells.map(\.end).max() ?? now
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(max(0, lastEnd - Date.timeIntervalSinceReferenceDate) + 0.1))
            guard let self else { return }
            let time = Date.timeIntervalSinceReferenceDate
            shells.removeAll { $0.end < time }
        }
    }
}

/// 画面全体に重ねる演出の層（タップは下へ通す）
struct FireworksEffectsLayer: View {
    let effects: FireworksEffects

    var body: some View {
        TimelineView(.animation(paused: effects.isIdle)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, _ in
                for shell in effects.shells {
                    draw(shell, at: time - shell.birth, in: context)
                }
            }
        }
        .ignoresSafeArea()
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { effects.visibleBounds = $0 }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func draw(_ shell: FireworksEffects.Shell, at t: TimeInterval, in context: GraphicsContext) {
        guard t >= 0 else { return }
        if let launch = shell.launch, t < shell.rise {
            drawRocket(from: launch, to: shell.center, progress: t / shell.rise, color: shell.color, in: context)
            return
        }
        let burstT = t - shell.rise
        let center = CGPoint(x: shell.center.x, y: shell.center.y + shell.droop * burstT * burstT)
        FireworkDrawing.drawBurst(in: context, center: center, radius: shell.radius, rays: shell.rays,
                                  rotation: shell.rotation, color: shell.color, t: burstT,
                                  duration: shell.duration, lineWidth: shell.lineWidth)
    }

    /// 打ち上がる火の玉と、その尾
    private func drawRocket(from launch: CGPoint, to apex: CGPoint, progress: Double,
                            color: FireworkColor, in context: GraphicsContext) {
        // 上へ行くほどゆっくりになる
        let eased = FireworkDrawing.easeOutCubic(progress)
        let wiggle = sin(progress * 22) * 1.5 * (1 - progress)
        let head = CGPoint(x: launch.x + (apex.x - launch.x) * eased + wiggle,
                           y: launch.y + (apex.y - launch.y) * eased)
        let tailLength = 46 * (1 - eased * 0.7)
        let dx = apex.x - launch.x, dy = apex.y - launch.y
        let length = max(sqrt(dx * dx + dy * dy), 1)
        let tail = CGPoint(x: head.x - dx / length * tailLength, y: head.y - dy / length * tailLength)

        var c = context
        c.blendMode = .plusLighter
        var line = Path()
        line.move(to: tail)
        line.addLine(to: head)
        c.stroke(line, with: .linearGradient(Gradient(colors: [color.mid.opacity(0), color.light.opacity(0.85)]),
                                             startPoint: tail, endPoint: head),
                 style: StrokeStyle(lineWidth: 2, lineCap: .round))
        let r = 2.2
        c.fill(Path(ellipseIn: CGRect(x: head.x - r, y: head.y - r, width: r * 2, height: r * 2)), with: .color(.white))
    }
}
