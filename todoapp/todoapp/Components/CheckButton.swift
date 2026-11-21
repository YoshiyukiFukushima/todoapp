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
    @State private var bounceTrigger = 0
    @State private var globalFrame: CGRect = .zero
    /// 泡がはじけるまでは、空の泡のまま見せる
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
            }
        } label: {
            CheckMarkFace(style: style, isCompleted: isCompleted && !isPopping,
                          isAnimated: animationsEnabled && !reduceMotion)
                .frame(width: style.checkboxSize, height: style.checkboxSize)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { globalFrame = $0 }
                .keyframeAnimator(initialValue: 1.0, trigger: bounceTrigger) { content, scale in
                    content.scaleEffect(scale)
                } keyframes: { _ in
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
                    }
                }
                .frame(width: DS.Size.minTapTarget, height: DS.Size.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: isCompleted) { old, new in !old && new }
        .accessibilityLabel(isCompleted ? "未完了に戻す" : "完了にする")
        .accessibilityValue(taskTitle)
    }
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
