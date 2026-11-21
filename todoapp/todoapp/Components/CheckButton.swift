//
//  CheckButton.swift
//  todoapp
//
//  タスクの完了チェック。タップ範囲は 44pt。完了時は弾み、触覚フィードバックを返す。
//  見た目と動きはテーマの描き方（ThemeStyle）で変わる。
//  - standard: 差し色の丸。小さく弾む
//  - bubble: シャボン玉。一度ふくらんでから縮み、はじける（輪と小さな泡は BubbleEffects が描く）
//  - flower: つぼみ。きゅっと縮んでから 6 枚の花びらがゆっくり開く（舞い落ちる花びらは FlowerEffects が描く）
//    外すと花びらが逆の順で閉じる
//  - water: しずくが落ちて当たると水玉に変わり、横につぶれてからぷるぷる揺れて戻る（しずくと波紋は WaterEffects が描く）
//

import SwiftUI

struct CheckButton: View {
    let isCompleted: Bool
    let taskTitle: String
    let animationsEnabled: Bool
    let action: () -> Void

    @Environment(\.dsStyle) private var style
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(BubbleEffects.self) private var bubbleEffects: BubbleEffects?
    @Environment(FlowerEffects.self) private var flowerEffects: FlowerEffects?
    @Environment(WaterEffects.self) private var waterEffects: WaterEffects?
    @State private var bounceTrigger = 0
    @State private var globalFrame: CGRect = .zero
    /// 泡がはじける・しずくが当たるまでは、未完了の見た目のまま見せる
    @State private var isPopping = false

    var body: some View {
        Button {
            let willComplete = !isCompleted
            action()
            guard willComplete, animationsEnabled, !reduceMotion else { return }
            bounceTrigger += 1
            let center = CGPoint(x: globalFrame.midX, y: globalFrame.midY)
            switch style {
            case .standard:
                break
            case .bubble:
                isPopping = true
                bubbleEffects?.pop(at: center, radius: globalFrame.width / 2)
                Task {
                    try? await Task.sleep(for: .seconds(DS.Bubble.popDelay))
                    isPopping = false
                }
            case .flower(let kind):
                flowerEffects?.shed(kind, at: center, radius: globalFrame.width / 2)
            case .water:
                isPopping = true
                waterEffects?.drop(at: center, radius: globalFrame.width / 2)
                Task {
                    try? await Task.sleep(for: .seconds(DS.Water.fallDuration))
                    isPopping = false
                }
            }
        } label: {
            CheckMarkFace(style: style, isCompleted: isCompleted && !isPopping,
                          isAnimated: animationsEnabled && !reduceMotion)
                .frame(width: style.checkboxSize, height: style.checkboxSize)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { globalFrame = $0 }
                .keyframeAnimator(initialValue: CheckScale(), trigger: bounceTrigger) { content, scale in
                    content.scaleEffect(x: scale.x, y: scale.y)
                } keyframes: { _ in
                    KeyframeTrack(\.x) { widthKeyframes }
                    KeyframeTrack(\.y) { heightKeyframes }
                }
                .frame(width: DS.Size.minTapTarget, height: DS.Size.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: isCompleted) { old, new in !old && new }
        .accessibilityLabel(isCompleted ? "未完了に戻す" : "完了にする")
        .accessibilityValue(taskTitle)
    }

    /// 横の伸び縮み。水滴だけは縦と別に動かして、つぶれてから揺れて戻る
    @KeyframeTrackContentBuilder<CGFloat>
    private var widthKeyframes: some KeyframeTrackContent<CGFloat> {
        switch style {
        case .water:
            // 落ちてくる間は待つ → 当たって横につぶれる → ぷるぷる揺れて戻る
            LinearKeyframe(1.0, duration: DS.Water.fallDuration)
            CubicKeyframe(1.36, duration: 0.07)
            CubicKeyframe(0.86, duration: 0.12)
            CubicKeyframe(1.1, duration: 0.11)
            CubicKeyframe(0.96, duration: 0.1)
            SpringKeyframe(1.0, duration: 0.2)
        default:
            uniformKeyframes
        }
    }

    @KeyframeTrackContentBuilder<CGFloat>
    private var heightKeyframes: some KeyframeTrackContent<CGFloat> {
        switch style {
        case .water:
            LinearKeyframe(1.0, duration: DS.Water.fallDuration)
            CubicKeyframe(0.66, duration: 0.07)
            CubicKeyframe(1.14, duration: 0.12)
            CubicKeyframe(0.92, duration: 0.11)
            CubicKeyframe(1.04, duration: 0.1)
            SpringKeyframe(1.0, duration: 0.2)
        default:
            uniformKeyframes
        }
    }

    /// 縦横そろえて大きさだけ変える動き
    @KeyframeTrackContentBuilder<CGFloat>
    private var uniformKeyframes: some KeyframeTrackContent<CGFloat> {
        switch style {
        case .standard:
            SpringKeyframe(1.25, duration: 0.12)
            SpringKeyframe(1.0, duration: 0.25)
        case .bubble:
            // ふくらむ → 縮む（ここではじける）→ 元に戻る
            CubicKeyframe(1.35, duration: 0.16)
            CubicKeyframe(0.7, duration: DS.Bubble.popDelay - 0.16)
            SpringKeyframe(1.0, duration: 0.35, spring: .bouncy)
        case .flower(let kind):
            // きゅっと縮む → 少し待つ → 花びらが開くのに合わせて、ゆっくり元の大きさへ
            let spec = kind.spec
            CubicKeyframe(0.74, duration: spec.squeeze)
            CubicKeyframe(0.74, duration: spec.bloomDelay - spec.squeeze)
            SpringKeyframe(1.0, duration: spec.bloomDuration * 0.7, spring: .smooth)
        case .water:
            LinearKeyframe(1.0, duration: 0.01)
        }
    }
}

/// チェックの丸の縦横の伸び縮み
private struct CheckScale {
    var x: CGFloat = 1
    var y: CGFloat = 1
}

/// チェックの見た目（テーマの描き方ごと）
private struct CheckMarkFace: View {
    let style: ThemeStyle
    let isCompleted: Bool
    let isAnimated: Bool

    @Environment(\.dsAccent) private var accent

    var body: some View {
        switch style {
        case .standard:
            ZStack {
                Circle()
                    .strokeBorder(accent.fill, lineWidth: DS.Stroke.check)
                    .opacity(isCompleted ? 0 : 1)
                Circle()
                    .fill(accent.fill)
                    .opacity(isCompleted ? 1 : 0)
                checkmark
            }
        case .bubble:
            ZStack {
                BubbleSphere(isFilled: isCompleted)
                checkmark
            }
            .animation(DS.Motion.fade, value: isCompleted)
        case .water:
            ZStack {
                BubbleSphere(isFilled: false, tint: DS.Water.glass)
                    .opacity(isCompleted ? 0 : 1)
                WaterBead()
                    .opacity(isCompleted ? 1 : 0)
            }
            .animation(isAnimated ? .easeOut(duration: 0.12) : nil, value: isCompleted)
        case .flower(let kind):
            FlowerBlossom(kind: kind, progress: isCompleted ? 1 : 0)
                .animation(isAnimated ? bloomAnimation(kind.spec) : nil, value: isCompleted)
        }
    }

    /// 咲くときはゆっくり、閉じるときは少し速く
    private func bloomAnimation(_ spec: FlowerSpec) -> Animation {
        isCompleted
            ? .easeOut(duration: spec.bloomDuration).delay(spec.bloomDelay)
            : .easeInOut(duration: spec.closeDuration)
    }

    private var checkmark: some View {
        Image(systemName: "checkmark")
            .font(DS.Typography.iconSmall)
            .foregroundStyle(accent.onFill)
            .opacity(isCompleted ? 1 : 0)
    }
}
