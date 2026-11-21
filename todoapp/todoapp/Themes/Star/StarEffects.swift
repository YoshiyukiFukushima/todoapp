//
//  StarEffects.swift
//  todoapp
//
//  星座のテーマの、夜空の星と光の動き。
//  - 夜空（ConstellationSky）：今のタブのタスクの数だけ星を置き、終えた数だけ灯す。全部終えると線でつながる
//  - launch：チェックした星から光が飛び、夜空の次の星に届いたところで、その星が灯る（StarEffectsLayer が描く）
//

import SwiftUI
import Observation

@Observable
final class StarEffects {
    fileprivate struct Flight {
        let from: CGPoint
        let starIndex: Int
        let birth: TimeInterval
        /// 飛ぶ道の曲がり具合（左右どちらにふくらむか）
        let bend: Double
    }

    /// 今の星座（タスクがなければ nil）
    private(set) var constellation: Constellation?
    /// 灯っている星の数（光が届いてから増える）
    private(set) var litCount = 0
    /// 星が灯った時刻（灯った瞬間に少し大きく光らせる）
    private(set) var litTimes: [Int: TimeInterval] = [:]
    /// 全部の星が灯った時刻（線を順に引き始める）
    private(set) var completedAt: TimeInterval?
    fileprivate private(set) var flights: [Flight] = []

    /// 終えた数から決まる、灯るべき星の数
    @ObservationIgnored private var targetLit = 0
    /// 夜空の星の、画面の上の位置（光の行き先）
    @ObservationIgnored var starPositions: [CGPoint] = []

    var isFlying: Bool { !flights.isEmpty }

    private var now: TimeInterval { Date.timeIntervalSinceReferenceDate }

    /// 今のタブの数に合わせる（一覧が変わるたびに呼ぶ）
    func sync(total: Int, done: Int) {
        let next = Constellation.forTaskCount(total)
        if next?.name != constellation?.name {
            constellation = next
            litTimes = [:]
            litCount = 0
            flights = []
        }
        let count = constellation?.stars.count ?? 0
        // 星より多くのタスクがあるときは、割合で灯す
        targetLit = total <= count ? done : Int((Double(done) * Double(count) / Double(max(total, 1))).rounded(.down))
        if total > 0, done == total { targetLit = count }

        if targetLit < litCount {
            // チェックを外した：その星はすぐ消す
            for index in targetLit..<litCount { litTimes[index] = nil }
            litCount = targetLit
        } else if targetLit > litCount + flights.count {
            // 演出なしで増えた（起動したとき・ほかの画面で終えたとき）：すぐ灯す
            litCount = targetLit - flights.count
        }
        updateCompletion()
    }

    /// チェックした星から、夜空の次の星へ光を飛ばす
    func launch(from point: CGPoint) {
        guard let constellation else { return }
        let index = min(litCount + flights.count, constellation.stars.count - 1)
        let flight = Flight(from: point, starIndex: index, birth: now, bend: .random(in: -1...1))
        flights.append(flight)
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(DS.Star.flightDuration))
            self?.arrive(flight)
        }
    }

    private func arrive(_ flight: Flight) {
        flights.removeAll { $0.birth == flight.birth && $0.starIndex == flight.starIndex }
        guard litCount < targetLit else { return }
        litTimes[litCount] = now
        litCount += 1
        updateCompletion()
    }

    private func updateCompletion() {
        let count = constellation?.stars.count ?? 0
        if count > 0, litCount == count, targetLit == count {
            if completedAt == nil { completedAt = now }
        } else {
            completedAt = nil
        }
    }
}

// MARK: - 夜空の星座（画面の背景に重ねる）

struct ConstellationSky: View {
    let effects: StarEffects

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var themeManager: ThemeManager

    private var isAnimated: Bool { themeManager.animationsEnabled && !reduceMotion }

    /// 星座を置く枠（画面に対する割合）。一覧の下の、空いていることが多いところ
    static let band = CGRect(x: 0.3, y: 0.66, width: 0.58, height: 0.16)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !isAnimated)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                draw(in: &context, size: size, time: isAnimated ? time : .infinity)
            }
        }
        .overlay {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { updatePositions(frame: proxy.frame(in: .global)) }
                    .onChange(of: proxy.frame(in: .global)) { _, frame in updatePositions(frame: frame) }
                    .onChange(of: effects.constellation?.name) { _, _ in updatePositions(frame: proxy.frame(in: .global)) }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func points(in size: CGSize) -> [CGPoint] {
        guard let constellation = effects.constellation else { return [] }
        let band = Self.band
        return constellation.stars.map { star in
            CGPoint(x: (band.minX + band.width * star.x) * size.width,
                    y: (band.minY + band.height * star.y) * size.height)
        }
    }

    private func updatePositions(frame: CGRect) {
        effects.starPositions = points(in: frame.size).map { CGPoint(x: $0.x + frame.minX, y: $0.y + frame.minY) }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        guard let constellation = effects.constellation else { return }
        let positions = points(in: size)

        // 線：全部の星が灯ったら、順番に引く
        if let completedAt = effects.completedAt {
            for (index, line) in constellation.lines.enumerated() {
                let start = completedAt + Double(index) * DS.Star.lineStagger
                let p = time.isInfinite ? 1 : min(max((time - start) / DS.Star.lineDuration, 0), 1)
                guard p > 0 else { continue }
                let a = positions[line.0], b = positions[line.1]
                var path = Path()
                path.move(to: a)
                path.addLine(to: CGPoint(x: a.x + (b.x - a.x) * p, y: a.y + (b.y - a.y) * p))
                context.stroke(path, with: .color(DS.Star.line.opacity(0.75)), lineWidth: 1.1)
            }
            // 名前：線を引き終わったら浮かび上がる
            let namesAt = completedAt + Double(constellation.lines.count) * DS.Star.lineStagger + DS.Star.lineDuration
            let alpha = time.isInfinite ? 1 : min(max((time - namesAt) / 0.6, 0), 1)
            if alpha > 0 {
                let text = Text(constellation.name)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(DS.Star.line.opacity(0.9 * alpha))
                let band = Self.band
                context.draw(text, at: CGPoint(x: (band.maxX) * size.width, y: (band.maxY + 0.03) * size.height),
                             anchor: .trailing)
            }
        }

        // 星：灯っていない星は暗い小さな点、灯った星は暖かく光る
        for (index, point) in positions.enumerated() {
            if index < effects.litCount {
                let since = time.isInfinite ? 10 : time - (effects.litTimes[index] ?? 0)
                // 灯った瞬間に大きく光って、落ち着く
                let pop = since < 0.5 ? 1 + 0.9 * sin(min(since / 0.5, 1) * .pi) : 1
                let twinkle = time.isInfinite ? 1 : 0.9 + 0.1 * sin(time * 2.2 + Double(index))
                let glow = 15 * pop * twinkle
                context.fill(Circle().path(in: CGRect(x: point.x - glow, y: point.y - glow, width: glow * 2, height: glow * 2)),
                             with: .radialGradient(Gradient(colors: [DS.Star.glow.opacity(0.55), DS.Star.glow.opacity(0)]),
                                                   center: point, startRadius: 0, endRadius: glow))
                let core = 3.6 * pop
                context.fill(Circle().path(in: CGRect(x: point.x - core, y: point.y - core, width: core * 2, height: core * 2)),
                             with: .color(DS.Star.goldLight))
            } else {
                let r = 3.0
                context.fill(Circle().path(in: CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)),
                             with: .color(DS.Star.unlitDim))
                context.stroke(Circle().path(in: CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)),
                               with: .color(DS.Star.unlit.opacity(0.5)), lineWidth: 0.6)
            }
        }
    }
}

// MARK: - 飛んでいく光（画面全体に重ねる層）

struct StarEffectsLayer: View {
    let effects: StarEffects

    var body: some View {
        TimelineView(.animation(paused: !effects.isFlying)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, _ in
                for flight in effects.flights {
                    draw(flight, at: time - flight.birth, in: &context)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// 光の粒と、うしろに伸びる尾。弧を描いて飛ぶ
    private func draw(_ flight: StarEffects.Flight, at t: TimeInterval, in context: inout GraphicsContext) {
        guard t >= 0, effects.starPositions.indices.contains(flight.starIndex) else { return }
        let target = effects.starPositions[flight.starIndex]
        let duration = DS.Star.flightDuration
        func position(_ time: TimeInterval) -> CGPoint {
            let p = min(max(time / duration, 0), 1)
            let eased = p < 0.5 ? 2 * p * p : 1 - pow(-2 * p + 2, 2) / 2
            let control = CGPoint(x: (flight.from.x + target.x) / 2 + flight.bend * 80,
                                  y: min(flight.from.y, target.y) - 40)
            let u = 1 - eased
            return CGPoint(x: u * u * flight.from.x + 2 * u * eased * control.x + eased * eased * target.x,
                           y: u * u * flight.from.y + 2 * u * eased * control.y + eased * eased * target.y)
        }
        for step in 0..<10 {
            let back = Double(step) * 0.025
            let point = position(t - back)
            let fade = 1 - Double(step) / 10
            let r = 3.2 * fade + 0.6
            context.fill(Circle().path(in: CGRect(x: point.x - r * 3, y: point.y - r * 3, width: r * 6, height: r * 6)),
                         with: .radialGradient(Gradient(colors: [DS.Star.glow.opacity(0.4 * fade), DS.Star.glow.opacity(0)]),
                                               center: point, startRadius: 0, endRadius: r * 3))
            context.fill(Circle().path(in: CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)),
                         with: .color(DS.Star.goldLight.opacity(fade)))
        }
    }
}
