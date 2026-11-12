//
//  ContentView.swift
//  todoapp
//
//  メイン画面：左のグループサイドバー＋上部（グループ名・進み具合・タブ）＋タスク一覧＋＋ボタン。
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var themeManager: ThemeManager

    @Query(sort: \TodoGroup.order) private var groups: [TodoGroup]
    @Query private var allTasks: [TodoTask]

    @State private var selectedGroupID: UUID?
    @State private var selectedFilter: TaskFilter = .day
    @State private var isSidebarOpen = false
    @State private var showAddTask = false
    @State private var showSettings = false
    @State private var selectedTask: TodoTask?
    @State private var editingGroup: TodoGroup?
    @State private var showAddGroup = false
    @State private var groupPendingDelete: TodoGroup?
    @State private var showDeleteGroupConfirm = false

    private var taskViewModel: TaskViewModel { TaskViewModel(modelContext: modelContext) }
    private var groupViewModel: GroupViewModel { GroupViewModel(modelContext: modelContext) }

    private var accent: DS.Accent { themeManager.selectedTheme.accent }

    private var selectedGroup: TodoGroup? {
        groups.first(where: { $0.id == selectedGroupID }) ?? groups.first
    }

    private var tasksInSelectedGroup: [TodoTask] {
        guard let selectedGroup else { return [] }
        return allTasks.filter { $0.group?.id == selectedGroup.id }
    }

    var body: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                GroupRail(
                    groups: groups,
                    selectedGroupID: selectedGroup?.id,
                    onToggle: { setSidebar(open: true) },
                    onSelect: select
                )
                .frame(width: DS.Size.sidebarCollapsed)

                mainColumn
            }
            .background(DS.Colors.background.ignoresSafeArea())

            if isSidebarOpen {
                DS.Colors.scrim
                    .ignoresSafeArea()
                    .onTapGesture { setSidebar(open: false) }
                    .accessibilityLabel("グループ一覧を閉じる")
                    .accessibilityAddTraits(.isButton)
                    .transition(.opacity)

                GroupSidebarPanel(
                    groups: groups,
                    selectedGroupID: selectedGroup?.id,
                    onClose: { setSidebar(open: false) },
                    onSelect: select,
                    onAdd: { showAddGroup = true },
                    onEdit: { editingGroup = $0 },
                    onDelete: { group in
                        groupPendingDelete = group
                        showDeleteGroupConfirm = true
                    },
                    onMove: moveGroups
                )
                .frame(width: DS.Size.sidebarExpanded)
                .transition(.move(edge: .leading))
            }
        }
        .confirmDelete(isPresented: $showDeleteGroupConfirm) {
            if let group = groupPendingDelete {
                groupViewModel.deleteGroup(group)
            }
        }
        .sheet(isPresented: $showAddTask) {
            if let group = selectedGroup {
                TaskEditSheet(group: group, subgroup: nil, task: nil, taskViewModel: taskViewModel)
                    .dsRoot(accent: accent)
            }
        }
        .sheet(item: $selectedTask) { task in
            TaskEditSheet(group: task.group, subgroup: task.subgroup, task: task, taskViewModel: taskViewModel)
                .dsRoot(accent: accent)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .dsRoot(accent: accent)
        }
        .sheet(item: $editingGroup) { group in
            GroupEditSheet(group: group, groupViewModel: groupViewModel)
                .dsRoot(accent: accent)
        }
        .sheet(isPresented: $showAddGroup) {
            GroupEditSheet(group: nil, groupViewModel: groupViewModel, nextOrder: groups.count)
                .dsRoot(accent: accent)
        }
        .dsRoot(accent: accent)
        .onAppear(perform: seedDefaultGroupIfNeeded)
        // 「先頭のグループ」を暗黙に選ぶと並べ替えで選択が変わるため、選択を明示的に持つ
        .onChange(of: groups.map(\.id), initial: true) { _, ids in
            if selectedGroupID == nil || !ids.contains(selectedGroupID!) {
                selectedGroupID = ids.first
            }
        }
    }

    // MARK: - 右側（上部＋一覧）

    @ViewBuilder
    private var mainColumn: some View {
        if let group = selectedGroup {
            VStack(spacing: 0) {
                VStack(spacing: DS.Spacing.m) {
                    MainHeaderView(
                        groupName: group.name,
                        filter: selectedFilter,
                        tasks: tasksInSelectedGroup,
                        onSettings: { showSettings = true }
                    )
                    FilterTabs(selection: $selectedFilter, tasks: tasksInSelectedGroup)
                }
                .padding(.horizontal, DS.Spacing.screenMargin)
                .padding(.top, DS.Spacing.s)
                .padding(.bottom, DS.Spacing.s)

                TaskListView(
                    group: group,
                    filter: selectedFilter,
                    taskViewModel: taskViewModel,
                    groupViewModel: groupViewModel,
                    onSelectTask: { selectedTask = $0 }
                )
            }
            .overlay(alignment: themeManager.addButtonPosition.alignment) {
                AddTaskButton(isEnabled: true) { showAddTask = true }
            }
        } else {
            ContentUnavailableView("グループがありません", systemImage: "folder",
                                   description: Text("左上のボタンからグループを追加できます。"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - 操作

    private func setSidebar(open: Bool) {
        withAnimation(DS.Motion.respecting(reduceMotion)) { isSidebarOpen = open }
    }

    private func select(_ group: TodoGroup) {
        selectedGroupID = group.id
        if isSidebarOpen { setSidebar(open: false) }
    }

    private func moveGroups(from source: IndexSet, to destination: Int) {
        var reordered = Array(groups)
        reordered.move(fromOffsets: source, toOffset: destination)
        groupViewModel.reorderGroups(reordered)
    }

    private func seedDefaultGroupIfNeeded() {
        guard groups.isEmpty else { return }
        groupViewModel.addGroup(name: "ホーム", icon: "🏠", colorHex: AppTheme.lavender.colorHex, order: 0)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TodoGroup.self, SubGroup.self, TodoTask.self], inMemory: true)
        .environmentObject(ThemeManager())
}
