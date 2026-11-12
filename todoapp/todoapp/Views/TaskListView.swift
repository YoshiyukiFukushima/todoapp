//
//  TaskListView.swift
//  todoapp
//

import SwiftUI
import SwiftData

struct TaskListView: View {
    let group: TodoGroup
    let filter: TaskFilter
    let taskViewModel: TaskViewModel
    let groupViewModel: GroupViewModel
    let onSelectTask: (TodoTask) -> Void

    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var taskPendingDelete: TodoTask?
    @State private var showDeleteConfirm = false
    @State private var manualExpandOverrides: [Int: Bool] = [:]
    @State private var showAddSubgroup = false
    @State private var newSubgroupName = ""
    @State private var renamingSubgroup: SubGroup?
    @State private var renameText = ""
    @State private var showRenameSubgroup = false
    @State private var subgroupPendingDelete: SubGroup?
    @State private var showDeleteSubgroup = false

    var body: some View {
        let query = TaskQuery()
        // 日・週・月・全て：未完了と完了を 1 つの一覧に（完了しても位置は変わらない）
        let ungrouped = query.listedTasks(from: group.tasks.filter { $0.subgroup == nil }, in: filter)
        let subgroups = group.subgroups.sorted(by: { $0.order < $1.order })
        let hasSubgroupTasks = subgroups.contains { !query.listedTasks(from: $0.tasks, in: filter).isEmpty }
        // 履歴：日付ごとの見出しつき
        let completed = filter == .history ? query.completedGroups(from: group.tasks, in: .history) : []

        Group {
            if ungrouped.isEmpty && !hasSubgroupTasks && completed.isEmpty {
                EmptyTasksView(filter: filter, addButtonPosition: themeManager.addButtonPosition)
            } else {
                List {
                    if !ungrouped.isEmpty {
                        Section {
                            ForEach(ungrouped) { task in row(for: task) }
                        } header: {
                            if themeManager.isStickyHeaderEnabled {
                                IncompleteSectionHeader(count: ungrouped.filter { !$0.isCompleted }.count)
                                    .listRowInsets(headerInsets)
                            }
                        }
                    }

                    if filter != .history {
                        ForEach(subgroups) { subgroup in
                            subgroupSection(subgroup, query: query)
                        }

                        AddSubgroupButton {
                            newSubgroupName = ""
                            showAddSubgroup = true
                        }
                        .listRowInsets(EdgeInsets(top: DS.Spacing.m, leading: DS.Spacing.screenMargin,
                                                  bottom: DS.Spacing.s, trailing: DS.Spacing.screenMargin))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }

                    ForEach(completed) { dateGroup in
                        completedSection(dateGroup)
                    }
                }
                .listStyle(.plain)
                .listSectionSpacing(DS.Spacing.s)
                .environment(\.defaultMinListHeaderHeight, 0)
                .scrollContentBackground(.hidden)
                .contentMargins(.bottom, DS.Size.fabClearance, for: .scrollContent)
            }
        }
        .background(DS.Colors.background)
        .alert("サブグループを追加", isPresented: $showAddSubgroup) {
            TextField("名前（例：週末の掃除）", text: $newSubgroupName)
            Button("追加") { addSubgroup() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("「\(group.name)」の中を見出しで分けられます。")
        }
        .alert("サブグループの名前を変更", isPresented: $showRenameSubgroup) {
            TextField("名前", text: $renameText)
            Button("変更") {
                let name = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                if let subgroup = renamingSubgroup, !name.isEmpty {
                    groupViewModel.updateSubGroup(subgroup, name: name)
                }
            }
            Button("キャンセル", role: .cancel) {}
        }
        .confirmationDialog(
            "「\(subgroupPendingDelete?.name ?? "")」を削除しますか？",
            isPresented: $showDeleteSubgroup,
            titleVisibility: .visible
        ) {
            Button("タスクを残して削除") {
                if let subgroup = subgroupPendingDelete {
                    groupViewModel.deleteSubGroup(subgroup, keepingTasks: true)
                }
            }
            Button("タスクも削除", role: .destructive) {
                if let subgroup = subgroupPendingDelete {
                    groupViewModel.deleteSubGroup(subgroup, keepingTasks: false)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("中のタスク \(subgroupPendingDelete?.tasks.count ?? 0)件を、残すか一緒に削除するかを選んでください。")
        }
        .confirmDelete(isPresented: $showDeleteConfirm) {
            if let task = taskPendingDelete {
                taskViewModel.delete(task)
            }
        }
    }

    // MARK: - サブグループ

    private func subgroupSection(_ subgroup: SubGroup, query: TaskQuery) -> some View {
        let listed = query.listedTasks(from: subgroup.tasks, in: filter)
        let done = listed.filter(\.isCompleted).count
        return Section {
            CollapsibleSectionHeader(
                title: subgroup.name,
                countText: "\(done)/\(listed.count)",
                isExpanded: subgroup.isExpanded
            ) {
                withAnimation(DS.Motion.respecting(reduceMotion)) {
                    groupViewModel.toggleExpanded(subgroup)
                }
            }
            .contextMenu {
                Button("名前を変更", systemImage: "pencil") {
                    renamingSubgroup = subgroup
                    renameText = subgroup.name
                    showRenameSubgroup = true
                }
                Button("削除", systemImage: "trash", role: .destructive) {
                    subgroupPendingDelete = subgroup
                    showDeleteSubgroup = true
                }
                .tint(DS.Colors.danger)
            }
            .accessibilityAction(named: "名前を変更") {
                renamingSubgroup = subgroup
                renameText = subgroup.name
                showRenameSubgroup = true
            }
            .accessibilityAction(named: "削除") {
                subgroupPendingDelete = subgroup
                showDeleteSubgroup = true
            }
            .listRowInsets(rowInsets)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if subgroup.isExpanded {
                ForEach(listed) { task in row(for: task) }
            }
        }
    }

    private func addSubgroup() {
        let name = newSubgroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        groupViewModel.addSubGroup(name: name, to: group, order: (group.subgroups.map(\.order).max() ?? -1) + 1)
    }

    // MARK: - 履歴（日付別）

    private func completedSection(_ dateGroup: CompletedDateGroup) -> some View {
        let expanded = isExpanded(dateGroup)
        return Section {
            if expanded {
                ForEach(dateGroup.tasks) { task in row(for: task) }
            }
        } header: {
            CollapsibleSectionHeader(
                title: dateGroup.label,
                countText: "\(dateGroup.tasks.count)",
                isExpanded: expanded,
                isMuted: true
            ) {
                withAnimation(DS.Motion.respecting(reduceMotion)) {
                    manualExpandOverrides[dateGroup.id] = !expanded
                }
            }
            .listRowInsets(headerInsets)
        }
    }

    private func isExpanded(_ dateGroup: CompletedDateGroup) -> Bool {
        manualExpandOverrides[dateGroup.id] ?? (themeManager.isCompletedSectionExpanded || dateGroup.id == 0)
    }

    // MARK: - 共通行

    private var headerInsets: EdgeInsets {
        EdgeInsets(top: DS.Spacing.s, leading: DS.Spacing.screenMargin, bottom: 0, trailing: DS.Spacing.screenMargin)
    }

    private var rowInsets: EdgeInsets {
        EdgeInsets(top: DS.Spacing.rowGap / 2, leading: DS.Spacing.screenMargin,
                   bottom: DS.Spacing.rowGap / 2, trailing: DS.Spacing.screenMargin)
    }

    private func row(for task: TodoTask) -> some View {
        TaskRowView(
            task: task,
            animationsEnabled: themeManager.animationsEnabled,
            fadeOutOnComplete: themeManager.fadeOutOnComplete,
            onTap: { onSelectTask(task) },
            onToggleComplete: { taskViewModel.toggleComplete(task) }
        )
        .listRowInsets(rowInsets)
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
