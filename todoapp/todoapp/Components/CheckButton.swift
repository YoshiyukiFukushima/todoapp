//
//  CheckButton.swift
//  todoapp
//
//  タスクの完了チェック。タップ範囲は 44pt。完了時は小さく弾み、触覚フィードバックを返す。
//

import SwiftUI

struct CheckButton: View {
    let isCompleted: Bool
    let taskTitle: String
    let animationsEnabled: Bool
    let action: () -> Void

    @Environment(\.dsAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bounceTrigger = 0

    var body: some View {
        Button {
            let willComplete = !isCompleted
            action()
            if willComplete, animationsEnabled, !reduceMotion {
                bounceTrigger += 1
            }
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(accent.fill, lineWidth: DS.Stroke.check)
                    .opacity(isCompleted ? 0 : 1)
                Circle()
                    .fill(accent.fill)
                    .opacity(isCompleted ? 1 : 0)
                Image(systemName: "checkmark")
                    .font(DS.Typography.iconSmall)
                    .foregroundStyle(accent.onFill)
                    .opacity(isCompleted ? 1 : 0)
            }
            .frame(width: DS.Size.checkbox, height: DS.Size.checkbox)
            .keyframeAnimator(initialValue: 1.0, trigger: bounceTrigger) { content, scale in
                content.scaleEffect(scale)
            } keyframes: { _ in
                SpringKeyframe(1.25, duration: 0.12)
                SpringKeyframe(1.0, duration: 0.25)
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
