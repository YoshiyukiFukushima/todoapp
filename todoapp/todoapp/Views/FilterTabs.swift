//
//  FilterTabs.swift
//  todoapp
//
//  日／週／月／全て／履歴 の丸いセグメント。
//

import SwiftUI

struct FilterTabs: View {
    @Binding var selection: TaskFilter
    let tasks: [TodoTask]

    @Namespace private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let query = TaskQuery()
        HStack(spacing: 0) {
            ForEach(TaskFilter.allCases) { filter in
                let isSelected = selection == filter
                let count = query.incompleteCount(in: tasks, for: filter)
                Button {
                    withAnimation(DS.Motion.respecting(reduceMotion)) { selection = filter }
                } label: {
                    HStack(spacing: DS.Spacing.xs) {
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
                    .frame(maxWidth: .infinity, minHeight: DS.Size.segmentHeight)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(DS.Colors.segmentSelected)
                                .dsShadow(.card)
                                .matchedGeometryEffect(id: "selected", in: namespace)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel(for: filter, count: count))
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(DS.Spacing.xs)
        .frame(minHeight: DS.Size.minTapTarget)
        .background(DS.Colors.surfaceSunken, in: Capsule())
    }

    private func accessibilityLabel(for filter: TaskFilter, count: Int?) -> String {
        guard let count else { return filter.label }
        return "\(filter.label)、未完了\(count)件"
    }
}
