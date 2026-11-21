//
//  ShishiEffects.swift
//  todoapp
//
//  ししおどしのテーマの演出。画面全体に重ねた 1 枚の層（ShishiEffectsLayer）で描く。
//  - knock: 竹筒が石を打った瞬間に「カコーン」と鳴らし、文字をチェックの上にふわっと浮かべる
//  水がたまって傾く動きそのものは、チェック（ShishiScene）が描く。
//  音はファイルを持たず、その場で作る（木を打つ短い音と、庭に響く余韻）。マナーモードでは鳴らない。
//

import SwiftUI
import Observation
import AVFoundation
import UIKit

@Observable
final class ShishiEffects {
    fileprivate struct Knock {
        let point: CGPoint
        let birth: TimeInterval
    }

    fileprivate private(set) var knocks: [Knock] = []

    var isIdle: Bool { knocks.isEmpty }

    /// 文字が浮かんで消えるまで
    static let textLife: TimeInterval = 1.6

    /// 水がたまって倒れ、戻って石を打つころに鳴らす
    func knock(at center: CGPoint, size: CGFloat) {
        let delay = DS.Shishi.hitDelay
        knocks.append(Knock(point: CGPoint(x: center.x + size * 0.3, y: center.y - size * 0.75), birth: now + delay))
        KnockSound.shared.prepare()
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            KnockSound.shared.play()
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.9)
            try? await Task.sleep(for: .seconds(Self.textLife + 0.1))
            guard let self else { return }
            let time = Date.timeIntervalSinceReferenceDate
            knocks.removeAll { time - $0.birth > Self.textLife }
        }
    }

    private var now: TimeInterval { Date.timeIntervalSinceReferenceDate }
}

/// 画面全体に重ねる演出の層（タップは下へ通す）
struct ShishiEffectsLayer: View {
    let effects: ShishiEffects

    var body: some View {
        TimelineView(.animation(paused: effects.isIdle)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, _ in
                guard let text = context.resolveSymbol(id: 0) else { return }
                for knock in effects.knocks {
                    let t = time - knock.birth
                    guard t >= 0, t <= ShishiEffects.textLife else { continue }
                    var c = context
                    // ぽんと出て、ゆっくり昇りながら消える（余韻）
                    let pop = Ease.outBack(t / 0.18, overshoot: 2.4)
                    c.opacity = 1 - Ease.smoothstep(0.5, ShishiEffects.textLife, t)
                    c.translateBy(x: knock.point.x, y: knock.point.y - 14 * Ease.outCubic(t / ShishiEffects.textLife))
                    c.scaleBy(x: pop, y: pop)
                    c.draw(text, at: .zero, anchor: .center)
                }
            } symbols: {
                Text("カコーン")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(DS.Shishi.bambooLight)
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
                    .tag(0)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - 「カコーン」の音

/// 竹が石を打つ音を、その場で作って鳴らす
@MainActor
final class KnockSound {
    static let shared = KnockSound()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var buffer: AVAudioPCMBuffer?

    /// 先に音を作っておく（はじめて鳴らすときに遅れないように）
    func prepare() {
        guard buffer == nil else { return }
        let rate = 44_100.0
        guard let format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 1) else { return }
        let length = AVAudioFrameCount(rate * 1.4)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: length),
              let samples = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = length
        var noise = ThemeSeed(0x5415_0D0)
        // カ：乾いた打音（高めの短い響き＋一瞬の雑音）／コーン：中空の竹の余韻／庭に返るこだま
        func knock(_ t: Double) -> Double {
            guard t >= 0 else { return 0 }
            let click = (noise.next() * 2 - 1) * exp(-t / 0.004) * 0.5
            let wood = sin(2 * .pi * 1_180 * t) * exp(-t / 0.045) * 0.55
                + sin(2 * .pi * 1_760 * t) * exp(-t / 0.03) * 0.3
            let hollow = sin(2 * .pi * 640 * t + 0.4 * sin(2 * .pi * 3 * t)) * exp(-t / 0.32) * 0.42
                + sin(2 * .pi * 960 * t) * exp(-t / 0.18) * 0.16
            return click + wood + hollow
        }
        var peak = 0.0
        var values = [Double](repeating: 0, count: Int(length))
        for i in 0..<Int(length) {
            let t = Double(i) / rate
            let attack = min(t / 0.002, 1)
            let value = attack * (knock(t) + 0.28 * knock(t - 0.21) + 0.1 * knock(t - 0.43))
            values[i] = value
            peak = max(peak, abs(value))
        }
        for i in 0..<Int(length) {
            samples[i] = Float(values[i] / max(peak, 0.001) * 0.8)
        }
        self.buffer = buffer

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    func play() {
        prepare()
        guard let buffer else { return }
        do {
            // マナーモードでは鳴らさない。ほかのアプリの音楽は止めない
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            if !engine.isRunning { try engine.start() }
        } catch {
            return
        }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
    }
}
