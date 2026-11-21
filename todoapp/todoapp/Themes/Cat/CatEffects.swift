//
//  CatEffects.swift
//  todoapp
//
//  ねこのテーマの演出。画面全体に重ねた 1 枚の層（CatEffectsLayer）で描く。
//  - press: カードの下からねこの手が伸びてきて、チェックの丸を肉球で押して、また引っこむ（カードの外には出ない）
//  - celebrate: 全部終わったとき、画面の下からねこが顔を出して「にゃ〜」
//  スタンプそのものは、チェックの丸（CatPawCheck）が押しきったときに付ける。
//

import SwiftUI
import Observation

@Observable
final class CatEffects {
    fileprivate struct Press {
        /// 肉球を押す点
        let target: CGPoint
        /// スタンプの傾き（ねこの手も同じ向きで伸びてくる）
        let angle: Double
        /// ねこの手の大きさ（絵の 1 単位が何 pt か）
        let scale: Double
        /// ねこの手が見えてよい範囲（タスクカード）
        let clip: CGRect
        let birth: TimeInterval
    }

    fileprivate struct Peek {
        let birth: TimeInterval
    }

    fileprivate private(set) var presses: [Press] = []
    fileprivate private(set) var peeks: [Peek] = []

    var isIdle: Bool { presses.isEmpty && peeks.isEmpty }

    @ObservationIgnored fileprivate var visibleBounds: CGRect = .zero

    /// ねこの手がチェックを押す
    func press(at target: CGPoint, checkSize: CGFloat, stamp: PawStamp, card: CGRect) {
        // 肉球（絵の 46 単位）がチェックより少し大きく見えるくらい
        let scale = Double(checkSize) * 1.15 / PawPads.stampBox.width
        let clip = card.isEmpty ? CGRect(x: target.x - 200, y: target.y - 60, width: 400, height: 120) : card
        let offset = CGPoint(x: Double(checkSize) * stamp.dx, y: Double(checkSize) * stamp.dy)
        presses.append(Press(target: CGPoint(x: target.x + offset.x, y: target.y + offset.y),
                             angle: stamp.angle, scale: scale, clip: clip, birth: now))
        scheduleCleanup(after: DS.Cat.armDuration)
    }

    /// 全部終わったときのご褒美：ねこが顔を出す
    func celebrate() {
        peeks.append(Peek(birth: now + DS.Cat.peekDelay))
        scheduleCleanup(after: DS.Cat.peekDelay + DS.Cat.peekDuration)
    }

    private var now: TimeInterval { Date.timeIntervalSinceReferenceDate }

    private func scheduleCleanup(after delay: TimeInterval) {
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(delay + 0.1))
            guard let self else { return }
            let time = Date.timeIntervalSinceReferenceDate
            presses.removeAll { time - $0.birth > DS.Cat.armDuration }
            peeks.removeAll { time - $0.birth > DS.Cat.peekDuration }
        }
    }
}

/// 画面全体に重ねる演出の層（タップは下へ通す）
struct CatEffectsLayer: View {
    let effects: CatEffects

    private enum Symbol: Hashable { case arm, face, speech }

    /// ねこの顔の大きさ
    private static let faceSize = CGSize(width: 150, height: 105)

    var body: some View {
        TimelineView(.animation(paused: effects.isIdle)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                guard let arm = context.resolveSymbol(id: Symbol.arm),
                      let face = context.resolveSymbol(id: Symbol.face),
                      let speech = context.resolveSymbol(id: Symbol.speech) else { return }
                for press in effects.presses {
                    draw(press, at: time - press.birth, arm: arm, in: context)
                }
                for peek in effects.peeks {
                    draw(peek, at: time - peek.birth, size: size, face: face, speech: speech, in: context)
                }
            } symbols: {
                CatArmView()
                    .frame(width: CatArmView.box.width, height: CatArmView.box.height)
                    .tag(Symbol.arm)
                CatFaceView()
                    .frame(width: Self.faceSize.width, height: Self.faceSize.height)
                    .tag(Symbol.face)
                CatSpeechBubble().tag(Symbol.speech)
            }
        }
        .ignoresSafeArea()
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { effects.visibleBounds = $0 }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: ねこの手

    /// 伸びる → 押す（少しつぶれる）→ 引っこむ。距離は「カードの下に隠れているところ」からの割合
    private static let reach: [(t: Double, rise: Double, sx: Double, sy: Double, tilt: Double)] = [
        (0.00, 1.00, 1.00, 1.00, 8),
        (0.36, -0.05, 1.00, 1.00, -1),
        (0.44, 0.00, 1.00, 1.00, 0),
        (0.54, 0.01, 1.08, 0.95, 0),
        (0.64, 0.01, 1.08, 0.95, 0),
        (0.72, -0.02, 1.00, 1.00, 0),
        (1.00, 1.00, 1.00, 1.00, 10),
    ]

    private func draw(_ press: CatEffects.Press, at t: TimeInterval, arm: GraphicsContext.ResolvedSymbol,
                      in context: GraphicsContext) {
        guard t >= 0, t <= DS.Cat.armDuration else { return }
        let p = t / DS.Cat.armDuration
        let frame = Self.sample(Self.reach, at: p)
        let angle = press.angle + frame.tilt
        // 肉球のまん中から指先・手首までが、カードの下に隠れきる距離
        let radians = angle * .pi / 180
        let hidden = (press.clip.maxY - press.target.y + 32 * press.scale) / max(cos(radians), 0.5)

        var c = context
        c.clip(to: RoundedRectangle(cornerRadius: DS.Radius.bubbleCard, style: .continuous).path(in: press.clip))
        c.addFilter(.shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 3))
        c.translateBy(x: press.target.x, y: press.target.y)
        c.rotate(by: .radians(radians))
        // 腕の向き（下）にそって伸び縮みする
        c.translateBy(x: 0, y: hidden * frame.rise)
        c.scaleBy(x: press.scale * frame.sx, y: press.scale * frame.sy)
        let box = CatArmView.box
        c.draw(arm, in: CGRect(x: -PawPads.center.x, y: -PawPads.center.y, width: box.width, height: box.height))
    }

    // MARK: 顔を出すねこ

    private func draw(_ peek: CatEffects.Peek, at t: TimeInterval, size: CGSize,
                      face: GraphicsContext.ResolvedSymbol, speech: GraphicsContext.ResolvedSymbol,
                      in context: GraphicsContext) {
        let duration = DS.Cat.peekDuration
        guard t >= 0, t <= duration else { return }
        let bounds = effects.visibleBounds.isEmpty ? CGRect(origin: .zero, size: size) : effects.visibleBounds
        let faceSize = Self.faceSize
        // 下からひょこっと出る → 首をかしげる → しばらくいて → 引っこむ
        let rise: Double
        if t < 0.65 {
            rise = Self.easeOutBack(t / 0.65)
        } else if t < duration - 0.6 {
            rise = 1
        } else {
            rise = 1 - Self.smoothstep((t - (duration - 0.6)) / 0.6)
        }
        let tilt = t > 0.7 && t < 1.9 ? sin((t - 0.7) / 1.2 * .pi * 2) * 7 : 0

        let base = CGPoint(x: bounds.minX + bounds.width * 0.3, y: bounds.maxY + 10)
        var c = context
        c.translateBy(x: base.x, y: base.y - (faceSize.height - 8) * rise)
        c.rotate(by: .degrees(tilt))
        c.draw(face, at: CGPoint(x: 0, y: faceSize.height / 2), anchor: .center)

        // 吹き出しは少し遅れて、ぽんと出る
        let speechT = (t - 0.75) / 0.3
        guard speechT > 0, rise > 0.9 else { return }
        var s = context
        s.opacity = min(speechT, 1) * min(rise, 1)
        s.translateBy(x: base.x + faceSize.width * 0.48, y: base.y - faceSize.height - 6)
        let pop = Self.easeOutBack(min(speechT, 1))
        s.scaleBy(x: pop, y: pop)
        s.draw(speech, at: .zero, anchor: .bottomLeading)
    }

    // MARK: 計算

    private static func sample(_ keys: [(t: Double, rise: Double, sx: Double, sy: Double, tilt: Double)],
                               at p: Double) -> (rise: Double, sx: Double, sy: Double, tilt: Double) {
        guard let next = keys.firstIndex(where: { $0.t >= p }), next > 0 else {
            let k = keys[0]
            return (k.rise, k.sx, k.sy, k.tilt)
        }
        let a = keys[next - 1], b = keys[next]
        let u = smoothstep((p - a.t) / (b.t - a.t))
        func mix(_ x: Double, _ y: Double) -> Double { x + (y - x) * u }
        return (mix(a.rise, b.rise), mix(a.sx, b.sx), mix(a.sy, b.sy), mix(a.tilt, b.tilt))
    }

    private static func smoothstep(_ x: Double) -> Double {
        let t = min(max(x, 0), 1)
        return t * t * (3 - 2 * t)
    }

    private static func easeOutBack(_ x: Double) -> Double {
        let t = min(max(x, 0), 1)
        let c1 = 1.7, c3 = c1 + 1
        let u = t - 1
        return 1 + c3 * u * u * u + c1 * u * u
    }
}
