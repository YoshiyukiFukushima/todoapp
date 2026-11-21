//
//  TaskRowView.swift
//  todoapp
//

import SwiftUI

struct TaskRowView: View {
    let task: TodoTask
    /// どのグループのタスクかを出す（すべてのグループを見ているとき）
    var showsGroup = false
    let animationsEnabled: Bool
    let fadeOutOnComplete: Bool
    let onTap: () -> Void
    let onToggleComplete: () -> Void

    @Environment(\.dsStyle) private var style
    @Environment(BubbleEffects.self) private var bubbleEffects: BubbleEffects?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sinkTrigger = 0
    /// カードの画面上の位置（ねこの手がカードの中だけに見えるようにする）
    @State private var cardFrame: CGRect = .zero

    /// 肉球の向き・花火の色を決める種（タスクごとに決まる。ウィジェットとも同じになる）
    private var seed: UInt64 {
        var random = ThemeSeed(id: task.id)
        return UInt64(random.next() * Double(UInt32.max))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            CheckButton(
                isCompleted: task.isCompleted,
                taskTitle: task.title,
                animationsEnabled: animationsEnabled,
                seed: seed,
                cardFrame: cardFrame,
                action: onToggleComplete
            )
            // ねこ・花火・ひよこは、チェックの絵（肉球・花火の玉・ひよこ）が主役なので薄くしない
            .opacity(style.keepsCheckBright ? 1 : rowOpacity)
            .padding(.leading, style.glassTint != nil ? DS.Spacing.s : DS.Spacing.xs)
            .padding(.top, DS.Spacing.xs)

            Button(action: onTap) {
                TaskRowContent(task: task, showsGroup: showsGroup)
                    .padding(.vertical, DS.Spacing.m)
                    .padding(.trailing, DS.Spacing.l)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("詳細を開く")
            .opacity(rowOpacity)
        }
        // 水滴のテーマ：終えたカードの下半分に水がたまる（ガラスの上、文字の下）
        // ろうそくのテーマ：まだのカードは火に照らされ、終えると暗くなる
        .background {
            Group {
                switch style {
                case .water:
                    WaterPool(isFilled: task.isCompleted, isAnimated: isAnimated)
                        .clipShape(RoundedRectangle(cornerRadius: style.cardRadius, style: .continuous))
                case .candle:
                    CandleCardLight(isLit: !task.isCompleted, isAnimated: isAnimated,
                                    phase: Double(StampMark.stableSeed(for: task.title) % 628) / 100)
                        .clipShape(RoundedRectangle(cornerRadius: style.cardRadius, style: .continuous))
                default:
                    EmptyView()
                }
            }
            .opacity(rowOpacity)
        }
        .background {
            DSSurface(shape: .card, elevation: task.isCompleted ? .none : .card)
                .opacity(rowOpacity)
        }
        // 全部終わったときに、このカードから泡をあふれさせるため位置を知らせる
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
            if style.hasCompletionEffects { bubbleEffects?.updateCardFrame(frame, for: task.id) }
            if style == .cat { cardFrame = frame }
        }
        .onDisappear { bubbleEffects?.removeCardFrame(for: task.id) }
        // 判子のテーマ：判子が紙に当たった瞬間、カードがぐっと沈む
        .keyframeAnimator(initialValue: CGFloat(0), trigger: sinkTrigger) { content, depth in
            content.offset(y: depth)
        } keyframes: { _ in
            LinearKeyframe(0, duration: DS.Stamp.pressDelay)
            CubicKeyframe(DS.Stamp.sinkDepth, duration: 0.05)
            SpringKeyframe(0, duration: 0.35, spring: .bouncy)
        }
        .onChange(of: task.isCompleted) { _, isCompleted in
            if isCompleted, style == .stamp, isAnimated { sinkTrigger += 1 }
        }
        .animation(fadeOutOnComplete ? DS.Motion.fade : nil, value: task.isCompleted)
    }

    private var isAnimated: Bool { animationsEnabled && !reduceMotion }

    /// 終えた行の薄さ。判子は押した印を見せたいので、薄くしすぎない
    private var completedOpacity: Double {
        style == .stamp ? 0.85 : DS.Opacity.completed
    }

    /// 今の行の薄さ（終えた行だけ薄くする）
    private var rowOpacity: Double { task.isCompleted ? completedOpacity : 1 }
}

/// タイトル・期限と繰り返し・メモ
private struct TaskRowContent: View {
    let task: TodoTask
    let showsGroup: Bool

    /// 行に出すグループ（アイコンと名前）
    private var groupMeta: (symbol: String, name: String)? {
        guard showsGroup, let group = task.group else { return nil }
        if case .symbol(let symbol) = group.glyph { return (symbol, group.name) }
        return ("folder", group.name)
    }

    private var memoText: String {
        task.memoDisplayMode == 1 ? String(task.memo.prefix(DS.Layout.memoPreviewLength)) : task.memo
    }

    private var dueLabel: DueLabel? {
        task.dueDate.map { TaskQuery().dueLabel(for: $0, isCompleted: task.isCompleted) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
            Text(task.title)
                .font(DS.Typography.taskTitle)
                .strikethrough(task.isCompleted, color: DS.Colors.textSecondary)
                .foregroundStyle(task.isCompleted ? DS.Colors.textSecondary : DS.Colors.textPrimary)
                .multilineTextAlignment(.leading)

            if groupMeta != nil || dueLabel != nil || task.isRepeating {
                HStack(spacing: DS.Spacing.s) {
                    if let groupMeta {
                        MetaItem(symbol: groupMeta.symbol, text: groupMeta.name)
                            .foregroundStyle(DS.Colors.textSecondary)
                            .lineLimit(1)
                    }
                    if let dueLabel {
                        MetaItem(symbol: dueLabel.isOverdue ? "exclamationmark.circle.fill" : "calendar", text: dueLabel.text)
                            .foregroundStyle(dueLabel.isOverdue ? DS.Colors.danger : DS.Colors.textSecondary)
                    }
                    if task.isRepeating {
                        MetaItem(symbol: "repeat", text: task.repeatIntervalEnum.displayName)
                            .foregroundStyle(DS.Colors.textSecondary)
                    }
                }
                .font(DS.Typography.caption)
            }

            if task.memoDisplayMode > 0 && !task.memo.isEmpty {
                Text(memoText)
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .lineLimit(task.memoDisplayMode == 1 ? 1 : nil)
                    .multilineTextAlignment(.leading)
                    .padding(.top, DS.Spacing.xxs)
            }
        }
    }
}

/// 期限・繰り返しなどの小さな「アイコン＋文字」
private struct MetaItem: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(spacing: DS.Spacing.xxs) {
            Image(systemName: symbol)
                .imageScale(.small)
            Text(text)
        }
    }
}
