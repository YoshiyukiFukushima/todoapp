//
//  TaskListView.swift
//  todoapp
//

import SwiftUI
import SwiftData

struct TaskListView: View {
    let group: TodoGroup?
    let filter: TaskFilter
    let taskViewModel: TaskViewModel
    let groupViewModel: GroupViewModel
    let onSelectTask: (TodoTask) -> Void

    @EnvironmentObject private var themeManager: ThemeManager
    @State private var taskPendingDelete: TodoTask?
    @State private var showDeleteConfirm = false
    @State private var manualExpandOverrides: [Int: Bool] = [:]

    var body: some View {
        Group {
            if let group {
                let query = TaskQuery()
                List {
                    if filter != .history {
                        incompleteSections(in: group, query: query)
                    }
                    completedSections(in: group, query: query)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .contentMargins(.bottom, DS.Size.fabClearance, for: .scrollContent)
            } else {
                ContentUnavailableView("グループを選択してください", systemImage: "folder")
            }
        }
        .background(DS.Colors.background)
        .confirmDelete(isPresented: $showDeleteConfirm) {
            if let task = taskPendingDelete {
                taskViewModel.delete(task)
            }
        }
    }

    // MARK: - 未完了

    @ViewBuilder
    private func incompleteSections(in group: TodoGroup, query: TaskQuery) -> some View {
        let ungrouped = query.incompleteTasks(from: group.tasks.filter { $0.subgroup == nil }, in: filter)
        if !ungrouped.isEmpty {
            Section {
                ForEach(ungrouped) { task in row(for: task) }
            } header: {
                if themeManager.isStickyHeaderEnabled {
                    IncompleteSectionHeader(count: ungrouped.count)
                }
            }
        }

        ForEach(group.subgroups.sorted(by: { $0.order < $1.order })) { subgroup in
            Section {
                SubGroupHeaderView(subgroup: subgroup) {
                    groupViewModel.toggleExpanded(subgroup)
                }
                .listRowBackground(Color.clear)
                if subgroup.isExpanded {
                    ForEach(query.incompleteTasks(from: subgroup.tasks, in: filter)) { task in row(for: task) }
                }
            }
        }
    }

    // MARK: - 完了済み（日付別）

    @ViewBuilder
    private func completedSections(in group: TodoGroup, query: TaskQuery) -> some View {
        ForEach(query.completedGroups(from: group.tasks, in: filter)) { dateGroup in
            let expanded = isExpanded(dateGroup)
            Section {
                if expanded {
                    ForEach(dateGroup.tasks) { task in row(for: task) }
                }
            } header: {
                CompletedSectionHeader(label: dateGroup.label, count: dateGroup.tasks.count, isExpanded: expanded) {
                    withAnimation(DS.Motion.standard) {
                        manualExpandOverrides[dateGroup.id] = !expanded
                    }
                }
            }
        }
    }

    private func isExpanded(_ dateGroup: CompletedDateGroup) -> Bool {
        manualExpandOverrides[dateGroup.id] ?? (themeManager.isCompletedSectionExpanded || dateGroup.id == 0)
    }

    // MARK: - 共通行

    private func row(for task: TodoTask) -> some View {
        TaskRowView(
            task: task,
            animationsEnabled: themeManager.animationsEnabled,
            emojiEffectEnabled: themeManager.emojiEffectEnabled,
            fadeOutOnComplete: themeManager.fadeOutOnComplete,
            onTap: { onSelectTask(task) },
            onToggleComplete: { taskViewModel.toggleComplete(task) }
        )
        .listRowInsets(EdgeInsets(top: DS.Spacing.xs, leading: DS.Spacing.l, bottom: DS.Spacing.xs, trailing: DS.Spacing.l))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                taskPendingDelete = task
                showDeleteConfirm = true
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }
}
