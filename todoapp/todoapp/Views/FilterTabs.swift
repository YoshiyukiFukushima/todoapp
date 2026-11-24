//
//  FilterTabs.swift
//  todoapp
//
//  画面上部の絞り込み。今日から順に左から日付が並び（横にスクロールできる）、右端に「全て」「履歴」。
//  - 日付をタップ：その 1 日だけを選ぶ
//  - 日付を長押し：今選んでいる日から、その日までをまとめて選ぶ。そのまま指を横に動かすと範囲を変えられる
//  続けて選んだ日は、1 つのつながったカプセルで囲む。
//

import SwiftUI

struct FilterTabs: View {
    @Binding var selection: TaskFilter
    let tasks: [TodoTask]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// 並べる日数（今日から 4 週間）
    static let dayCount = 28
    /// 日付 1 つぶんの、いちばん狭い幅
    static let minDayWidth: CGFloat = 40

    /// 日付の並びの、見えている幅
    @State private var stripWidth: CGFloat = 0
    /// いちばん左に見えている日（スクロールの位置）
    @State private var firstVisible: Int?

    /// 長押しで範囲を選んでいるあいだの、はじまりの日と、指の下の日（nil なら選んでいない）
    @State private var rangeAnchor: Int?
    @State private var rangeEnd = 0
    /// 長押しのまま左右の端に来たとき、そちらへ 1 日ずつ送る（+1 / -1 / 0）
    @State private var edgeDirection = 0
    @State private var edgeScrollTask: Task<Void, Never>?
    /// 長押しで範囲を選び終えた時刻（指を離したときのタップで、1 日に戻らないようにする）
    @State private var rangeEndedAt: Date = .distantPast

    /// 一度に見える日の数（端の日が欠けないよう、幅を割りきれる数にする）
    private var visibleCount: Int {
        guard stripWidth > 0 else { return 5 }
        return max(3, Int(stripWidth / Self.minDayWidth))
    }

    /// 日付 1 つぶんの幅（見える幅を、見える日の数でちょうど割る）
    private var dayWidth: CGFloat {
        stripWidth > 0 ? stripWidth / CGFloat(visibleCount) : Self.minDayWidth
    }

    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            ScrollView(.horizontal, showsIndicators: false) {
                dayStrip
            }
            // 1 日ぶんずつ止まるので、端の日が半分だけ見えることはない
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $firstVisible, anchor: .leading)
            .scrollDisabled(rangeAnchor != nil)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { stripWidth = $0 }
            .clipShape(Capsule())
            .onAppear(perform: revealSelection)

            Rectangle()
                .fill(DS.Colors.separator)
                .frame(width: 1, height: DS.Size.segmentHeight * 0.6)

            HStack(spacing: 0) {
                fixedTab(.all)
                fixedTab(.history)
            }
            .fixedSize()
        }
        .padding(DS.Spacing.xs)
        .frame(minHeight: DS.Size.minTapTarget)
        .background(DS.Colors.surfaceSunken, in: Capsule())
        .sensoryFeedback(.selection, trigger: selection)
    }

    // MARK: - 日付の並び

    private var selectedRange: DayRange? {
        if case .days(let range) = selection { return range }
        return nil
    }

    private var dayStrip: some View {
        let query = TaskQuery()
        let width = dayWidth
        return ZStack(alignment: .leading) {
            // 選んだ日（続いた何日か）を 1 つのカプセルで囲む
            if let range = selectedRange {
                SelectedTabSurface()
                    .frame(width: width * CGFloat(range.count), height: DS.Size.segmentHeight + 8)
                    .offset(x: width * CGFloat(range.start))
            }
            HStack(spacing: 0) {
                ForEach(0..<Self.dayCount, id: \.self) { offset in
                    DayCell(offset: offset, date: query.date(atOffset: offset),
                            isSelected: selectedRange?.contains(offset) ?? false,
                            hasTasks: (query.incompleteCount(in: tasks, for: .days(DayRange(start: offset))) ?? 0) > 0,
                            query: query)
                        .frame(width: width)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard Date().timeIntervalSince(rangeEndedAt) > 0.3 else { return }
                            select(.days(DayRange(start: offset)))
                        }
                        .id(offset)
                        .accessibilityAction { select(.days(DayRange(start: offset))) }
                        .accessibilityAction(named: "ここまでまとめて選ぶ") { extendSelection(to: offset) }
                }
            }
            .scrollTargetLayout()
        }
        // SwiftUI のドラッグはスクロールを止めてしまうので、UIKit の長押しで受ける（動かせば、ふつうにスクロールする）
        .gesture(LongPressDragGesture(minimumDuration: 0.35) { location, state in
            handleRange(at: location, state: state)
        })
    }

    /// 長押し → 指を動かして何日か（タップは日付ごと）。端まで行くと、その先へ 1 日ずつ送る
    private func handleRange(at location: CGPoint, state: UIGestureRecognizer.State) {
        switch state {
        case .began:
            // 今選んでいる日をはじまりにする（日付以外を選んでいたら、押した日から）
            let pressed = index(at: location.x)
            rangeAnchor = selectedRange?.start ?? pressed
            rangeEnd = pressed
            select(.days(DayRange.between(rangeAnchor ?? pressed, pressed)))
            updateEdgeScroll()
        case .changed:
            guard let anchor = rangeAnchor else { return }
            rangeEnd = index(at: location.x)
            select(.days(DayRange.between(anchor, rangeEnd)))
            updateEdgeScroll()
        default:
            finishRange()
        }
    }

    private func index(at x: CGFloat) -> Int {
        min(max(Int(x / dayWidth), 0), Self.dayCount - 1)
    }

    /// 指の下の日が、見えている範囲の左右の端なら、そちらへ送りはじめる
    private func updateEdgeScroll() {
        let first = firstVisible ?? 0
        let last = first + visibleCount - 1
        if rangeEnd >= last, last < Self.dayCount - 1 {
            edgeDirection = 1
        } else if rangeEnd <= first, first > 0 {
            edgeDirection = -1
        } else {
            edgeDirection = 0
        }
        guard edgeDirection != 0, edgeScrollTask == nil else { return }
        edgeScrollTask = Task { @MainActor in
            while !Task.isCancelled, edgeDirection != 0, let anchor = rangeAnchor {
                try? await Task.sleep(for: .seconds(0.3))
                guard !Task.isCancelled, edgeDirection != 0 else { break }
                let first = firstVisible ?? 0
                let next = min(max(first + edgeDirection, 0), Self.dayCount - visibleCount)
                guard next != first else { break }
                withAnimation(.easeOut(duration: 0.2)) { firstVisible = next }
                rangeEnd = min(max(rangeEnd + edgeDirection, 0), Self.dayCount - 1)
                select(.days(DayRange.between(anchor, rangeEnd)))
            }
            edgeScrollTask = nil
        }
    }

    /// 指を離した（または取り消された）ら、範囲選びを終える
    private func finishRange() {
        edgeScrollTask?.cancel()
        edgeScrollTask = nil
        edgeDirection = 0
        if rangeAnchor != nil { rangeEndedAt = Date() }
        rangeAnchor = nil
    }

    private func select(_ filter: TaskFilter) {
        guard selection != filter else { return }
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.22)) { selection = filter }
    }

    /// 今選んでいる日から offset の日までをまとめて選ぶ（読み上げの操作）
    private func extendSelection(to offset: Int) {
        let anchor = selectedRange?.start ?? offset
        select(.days(DayRange.between(anchor, offset)))
    }

    /// 開いたとき、選んでいる日が見えないところにあれば、見えるところまで送る
    private func revealSelection() {
        guard let range = selectedRange, range.start >= visibleCount else { return }
        firstVisible = min(range.start, Self.dayCount - visibleCount)
    }

    // MARK: - 全て・履歴

    private func fixedTab(_ filter: TaskFilter) -> some View {
        let isSelected = selection == filter
        let count = TaskQuery().incompleteCount(in: tasks, for: filter)
        return Button {
            select(filter)
        } label: {
            HStack(spacing: DS.Spacing.xxs) {
                Text(filter.label)
                    .font(isSelected ? DS.Typography.tabSelected : DS.Typography.tab)
                if let count, count > 0 {
                    Text("\(count)")
                        .font(DS.Typography.counter)
                        .foregroundStyle(isSelected ? DS.Colors.textSecondary : DS.Colors.textTertiary)
                }
            }
            .lineLimit(1)
            .foregroundStyle(isSelected ? DS.Colors.textPrimary : DS.Colors.textSecondary)
            .padding(.horizontal, DS.Spacing.s)
            .frame(minHeight: DS.Size.segmentHeight + 8)
            .background {
                if isSelected { SelectedTabSurface() }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(count.map { "\(filter.label)、未完了\($0)件" } ?? filter.label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    /// 選んだところのカプセル（泡・花・水滴などのテーマではガラス）
    private struct SelectedTabSurface: View {
        @Environment(\.dsStyle) private var style

        var body: some View {
            switch style {
            case .standard:
                Capsule().fill(DS.Colors.segmentSelected).dsShadow(.card)
            case .bubble, .flower, .water, .stamp, .candle, .constellation, .fireworks,
                 .balloon, .jelly, .paperPlane, .shishiOdoshi, .butterfly,
                 .planet, .snowman, .weather:
                DSSurface(shape: .capsule)
            }
        }
    }
}

/// 日付 1 つ（曜日と日にち。今日は「今日」、月のはじめは「12月」。まだのタスクがある日は小さな点）
private struct DayCell: View {
    let offset: Int
    let date: Date
    let isSelected: Bool
    let hasTasks: Bool
    let query: TaskQuery

    @Environment(\.dsAccent) private var accent

    private var day: Int { query.calendar.component(.day, from: date) }
    private var weekday: Int { query.calendar.component(.weekday, from: date) }

    private var topLabel: String {
        if offset == 0 { return "今日" }
        if day == 1 { return "\(query.calendar.component(.month, from: date))月" }
        return ["日", "月", "火", "水", "木", "金", "土"][weekday - 1]
    }

    /// 土曜は青、日曜は赤（ほんのり）
    private var topColor: Color {
        switch weekday {
        case 1 where offset != 0 && day != 1: DS.Colors.danger.opacity(0.85)
        case 7 where offset != 0 && day != 1: DS.Colors.textSecondary
        default: isSelected ? DS.Colors.textSecondary : DS.Colors.textTertiary
        }
    }

    var body: some View {
        VStack(spacing: 1) {
            Text(topLabel)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(topColor)
            Text("\(day)")
                .font(isSelected ? DS.Typography.tabSelected : DS.Typography.tab)
                .monospacedDigit()
                .foregroundStyle(isSelected ? DS.Colors.textPrimary : DS.Colors.textSecondary)
            Circle()
                .fill(accent.fill)
                .frame(width: 4, height: 4)
                .opacity(hasTasks ? 1 : 0)
        }
        .lineLimit(1)
        .frame(height: DS.Size.segmentHeight + 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var accessibilityText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日 EEEE"
        let name = offset == 0 ? "今日、" : offset == 1 ? "明日、" : ""
        return name + formatter.string(from: date) + (hasTasks ? "、まだのタスクあり" : "")
    }
}

/// 長押ししてから指を動かすあいだ、指の位置を知らせる（UIKit の長押し。スクロールとけんかしない）
private struct LongPressDragGesture: UIGestureRecognizerRepresentable {
    var minimumDuration: TimeInterval
    var onChange: (CGPoint, UIGestureRecognizer.State) -> Void

    func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let recognizer = UILongPressGestureRecognizer()
        recognizer.minimumPressDuration = minimumDuration
        return recognizer
    }

    func handleUIGestureRecognizerAction(_ recognizer: UILongPressGestureRecognizer, context: Context) {
        onChange(context.converter.localLocation, recognizer.state)
    }
}
