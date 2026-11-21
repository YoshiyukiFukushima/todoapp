//
//  TaskListWidgetViews.swift
//  TodoWidgets
//
//  ホーム画面の中・大のウィジェット。アプリのテーマ（差し色・モノクロ・泡）に合わせる（docs/widgets.md 4.5）。
//

import AppIntents
import SwiftUI
import WidgetKit

/// テーマの色をウィジェットで使う（ウィジェットにはアプリのトレイトが届かないので、色の表から直接取る）
struct WidgetColors {
    let theme: ColorTheme
    let colorScheme: ColorScheme

    func color(_ token: DSColorToken) -> Color {
        Color(uiColor: theme.palette[token].resolve(isDark: colorScheme == .dark))
    }

    var background: Color { color(.background) }
    var surface: Color { color(.surface) }
    var textPrimary: Color { color(.textPrimary) }
    var textSecondary: Color { color(.textSecondary) }
    var textTertiary: Color { color(.textTertiary) }
    var separator: Color { color(.separator) }
    var success: Color { color(.success) }
    var accent: DS.Accent { theme.accent }
}

// MARK: - 背景

struct TaskWidgetBackground: View {
    let theme: ColorTheme

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        switch theme.style {
        case .standard:
            WidgetColors(theme: theme, colorScheme: colorScheme).background
        case .bubble:
            // 泡は動かない絵にする（ウィジェットは動き続ける演出ができない）
            BubbleBackdrop(isAnimated: false)
        case .flower(let kind):
            FlowerBackdrop(kind: kind, isAnimated: false)
        case .water:
            WaterBackdrop(isAnimated: false)
        case .stamp:
            WashiBackdrop()
        case .candle:
            CandleBackdrop()
        case .constellation:
            StarfieldBackdrop(isAnimated: false)
        }
    }
}

// MARK: - 中・大

struct TaskListWidgetView: View {
    let entry: TaskWidgetEntry

    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    private var colors: WidgetColors { WidgetColors(theme: entry.theme, colorScheme: colorScheme) }

    /// 入る行の数
    private var capacity: Int { family == .systemLarge ? 7 : 3 }

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemLarge ? DS.Spacing.s : DS.Spacing.xs) {
            header
            switch entry.state {
            case .tasks:
                if entry.items.isEmpty {
                    message(symbol: "checkmark.circle", text: "\(entry.scopeLabel)のタスクはありません")
                } else if entry.isAllDone && family != .systemLarge {
                    message(symbol: "checkmark.circle.fill", text: "\(entry.scopeLabel)の分はすべて完了", tint: colors.success)
                } else {
                    rows
                }
            case .sourceMissing:
                message(symbol: "questionmark.folder", text: "グループが見つかりません。長押しして選び直してください")
            case .noGroups:
                message(symbol: "folder.badge.plus", text: "アプリでグループを作ってください")
            }
            Spacer(minLength: 0)
        }
        .fontDesign(.rounded)
        .foregroundStyle(colors.textPrimary)
        .environment(\.dsAccent, entry.theme.accent)
    }

    // MARK: 見出し

    private var header: some View {
        Link(destination: entry.link) {
            HStack(spacing: DS.Spacing.s) {
                if family == .systemLarge, entry.state == .tasks, entry.total > 0 {
                    WidgetProgressRing(entry: entry, colors: colors)
                } else {
                    Image(systemName: entry.symbol)
                        .font(DS.Typography.caption)
                        .foregroundStyle(entry.theme.accent.text)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(entry.title)
                        .font(family == .systemLarge ? DS.Typography.sectionTitle : DS.Typography.taskTitle)
                        .lineLimit(1)
                    if family == .systemLarge, entry.state == .tasks {
                        Text(progressText)
                            .font(DS.Typography.caption)
                            .foregroundStyle(colors.textSecondary)
                    }
                }
                Spacer(minLength: DS.Spacing.xs)
                if family != .systemLarge, entry.state == .tasks, entry.total > 0 {
                    Text("\(entry.done)/\(entry.total)")
                        .font(DS.Typography.counter)
                        .foregroundStyle(colors.textSecondary)
                }
            }
        }
    }

    private var progressText: String {
        if entry.total == 0 { return "\(entry.scopeLabel) 0件" }
        if entry.isAllDone { return "\(entry.scopeLabel)の\(entry.total)件すべて完了" }
        return "\(entry.scopeLabel) \(entry.total)件中\(entry.done)件完了"
    }

    // MARK: 行

    private var rows: some View {
        let shown = Array(entry.items.prefix(capacity))
        let hidden = entry.items.count - shown.count
        return VStack(alignment: .leading, spacing: family == .systemLarge ? DS.Spacing.xs + DS.Spacing.xxs : DS.Spacing.xxs) {
            ForEach(shown) { item in
                WidgetTaskRow(item: item, colors: colors, isLarge: family == .systemLarge)
            }
            if hidden > 0 {
                Link(destination: entry.link) {
                    Text("ほか \(hidden)件")
                        .font(DS.Typography.caption)
                        .foregroundStyle(colors.textSecondary)
                        .padding(.leading, DS.Spacing.xs)
                }
            }
        }
    }

    private func message(symbol: String, text: String, tint: Color? = nil) -> some View {
        HStack(spacing: DS.Spacing.s) {
            Image(systemName: symbol)
                .font(DS.Typography.icon)
                .foregroundStyle(tint ?? entry.theme.accent.text)
            Text(text)
                .font(DS.Typography.meta)
                .foregroundStyle(colors.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 1 行：チェックの丸（タップで切り替え）＋タスク名（タップでアプリの詳細）＋期限
struct WidgetTaskRow: View {
    let item: WidgetTaskItem
    let colors: WidgetColors
    let isLarge: Bool

    private var checkSize: CGFloat { isLarge ? 24 : 20 }

    var body: some View {
        HStack(spacing: DS.Spacing.s) {
            Button(intent: ToggleTaskIntent(taskID: item.id)) {
                WidgetCheckFace(isCompleted: item.isCompleted, style: colors.theme.style, accent: colors.accent)
                    .frame(width: checkSize, height: checkSize)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isCompleted ? "未完了に戻す" : "完了にする")
            .accessibilityValue(item.title)

            Link(destination: AppLink.task(item.id).url) {
                HStack(spacing: DS.Spacing.xs) {
                    Text(item.title)
                        .font(isLarge ? DS.Typography.taskTitle : DS.Typography.meta)
                        .strikethrough(item.isCompleted, color: colors.textSecondary)
                        .foregroundStyle(item.isCompleted ? colors.textSecondary : colors.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: DS.Spacing.xs)
                    meta
                }
            }
        }
        .padding(.horizontal, colors.theme.style.glassTint != nil ? DS.Spacing.s : 0)
        .padding(.vertical, isLarge ? DS.Spacing.xxs + 1 : 1)
        .background {
            if let tint = colors.theme.style.glassTint {
                BubbleGlass(shape: Capsule(), tint: tint, highlight: .none, isDimmed: item.isCompleted)
            }
        }
        .opacity(item.isCompleted ? DS.Opacity.completed : 1)
    }

    @ViewBuilder
    private var meta: some View {
        HStack(spacing: DS.Spacing.xs) {
            if let groupName = item.groupName {
                HStack(spacing: DS.Spacing.xxs) {
                    if let symbol = item.groupSymbol {
                        Image(systemName: symbol).imageScale(.small)
                    }
                    Text(groupName).lineLimit(1)
                }
                .foregroundStyle(colors.textSecondary)
            }
            if let dueText = item.dueText {
                Text(dueText)
                    .foregroundStyle(item.isOverdue ? DS.Colors.danger : colors.textSecondary)
            }
        }
        .font(DS.Typography.caption)
    }
}

/// チェックの丸（テーマの描き方ごと）
struct WidgetCheckFace: View {
    let isCompleted: Bool
    let style: ThemeStyle
    let accent: DS.Accent

    var body: some View {
        switch style {
        case .standard:
            ZStack {
                if isCompleted {
                    Circle().fill(accent.fill)
                    Image(systemName: "checkmark")
                        .font(DS.Typography.iconSmall)
                        .foregroundStyle(accent.onFill)
                } else {
                    Circle().strokeBorder(accent.fill, lineWidth: DS.Stroke.check)
                }
            }
        case .bubble:
            ZStack {
                BubbleSphere(isFilled: isCompleted)
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(DS.Typography.iconSmall)
                        .foregroundStyle(accent.onFill)
                }
            }
        case .stamp:
            if isCompleted {
                StampMark(tilt: -6)
            } else {
                StampGuide()
            }
        case .candle:
            CandleFace(lit: isCompleted ? 0 : 1, isAnimated: false)
        case .constellation:
            StarFace(isLit: isCompleted)
        case .water:
            if isCompleted {
                WaterBead()
            } else {
                BubbleSphere(isFilled: false, tint: DS.Water.glass)
            }
        case .flower(let kind):
            // 咲いた花は外へ広がるので、行からはみ出しすぎないよう少し小さく描く
            FlowerBlossom(kind: kind, progress: isCompleted ? 1 : 0)
                .scaleEffect(isCompleted ? 0.72 : 1)
        }
    }
}

/// 大のウィジェットの進み具合の輪
struct WidgetProgressRing: View {
    let entry: TaskWidgetEntry
    let colors: WidgetColors

    var body: some View {
        ZStack {
            Circle().stroke(colors.color(.surfaceSunken), lineWidth: DS.Size.ringLineWidth - 1)
            Circle()
                .trim(from: 0, to: entry.fraction)
                .stroke(entry.isAllDone ? colors.success : entry.theme.accent.fill,
                        style: StrokeStyle(lineWidth: DS.Size.ringLineWidth - 1, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if entry.isAllDone {
                Image(systemName: "checkmark")
                    .font(DS.Typography.iconSmall)
                    .foregroundStyle(colors.success)
            }
        }
        .frame(width: 34, height: 34)
        .accessibilityHidden(true)
    }
}

// MARK: - ウィジェットの定義

struct TaskListWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: WidgetKinds.tasks, intent: TaskWidgetConfigIntent.self,
                               provider: TaskWidgetProvider()) { entry in
            TaskListWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    TaskWidgetBackground(theme: entry.theme)
                }
        }
        .configurationDisplayName("タスク")
        .description("今日やることを確認して、そのままチェックできます。")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
