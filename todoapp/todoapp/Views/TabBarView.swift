//
//  TabBarView.swift
//  todoapp
//

import SwiftUI

struct TabBarView: View {
    @Binding var selectedFilter: TaskFilter
    let tasks: [TodoTask]

    var body: some View {
        let query = TaskQuery()
        HStack(spacing: DS.Spacing.xxs) {
            ForEach(TaskFilter.allCases) { filter in
                FilterTabButton(
                    filter: filter,
                    count: query.incompleteCount(in: tasks, for: filter),
                    isSelected: selectedFilter == filter
                ) {
                    withAnimation(DS.Motion.standard) { selectedFilter = filter }
                }
            }
        }
        .padding(.horizontal, DS.Spacing.s)
        .padding(.top, DS.Spacing.s)
        .background(DS.Colors.surfaceSunken)
    }
}

/// フォルダのつまみ型のタブ 1 つ分
private struct FilterTabButton: View {
    let filter: TaskFilter
    let count: Int?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DS.Spacing.xxs) {
                Text(filter.label)
                    .font(isSelected ? DS.Typography.tabSelected : DS.Typography.tab)
                    .foregroundStyle(isSelected ? DS.Colors.textPrimary : DS.Colors.textSecondary)
                    .lineLimit(1)

                if let count {
                    Text("\(count)")
                        .font(DS.Typography.counter)
                        .foregroundStyle(DS.Colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.s)
            .background(isSelected ? DS.Colors.background : .clear)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: DS.Radius.s, topTrailingRadius: DS.Radius.s))
        }
        .buttonStyle(.plain)
    }
}
