//
//  ContentView.swift
//  todoapp
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager

    @Query(sort: \TodoGroup.order) private var groups: [TodoGroup]
    @Query private var allTasks: [TodoTask]

    @State private var selectedGroupID: UUID?
    @State private var selectedFilter: TaskFilter = .day
    @State private var showGroupManagement = false
    @State private var showAddTask = false
    @State private var showSettings = false
    @State private var selectedTask: TodoTask?

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
            NavigationStack {
                HStack(spacing: 0) {
                    GroupListView(
                        groups: groups,
                        selectedGroupID: Binding(
                            get: { selectedGroup?.id },
                            set: { selectedGroupID = $0 }
                        ),
                        onMenuTap: { withAnimation(DS.Motion.standard) { showGroupManagement = true } }
                    )
                    .frame(width: DS.Size.sidebarCollapsed)

                    Divider().overlay(DS.Colors.separator)

                    taskArea
                }
                .background(DS.Colors.background)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }

            if showGroupManagement {
                GroupManagementView(
                    groups: groups,
                    groupViewModel: groupViewModel,
                    isPresented: $showGroupManagement
                )
                .transition(.move(edge: .leading))
                .zIndex(1)
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
        .dsRoot(accent: accent)
        .onAppear(perform: seedDefaultGroupIfNeeded)
    }

    private var taskArea: some View {
        VStack(spacing: 0) {
            TabBarView(selectedFilter: $selectedFilter, tasks: tasksInSelectedGroup)

            TaskListView(
                group: selectedGroup,
                filter: selectedFilter,
                taskViewModel: taskViewModel,
                groupViewModel: groupViewModel,
                onSelectTask: { selectedTask = $0 }
            )
        }
        .overlay(alignment: themeManager.addButtonPosition.alignment) {
            AddTaskButton(isEnabled: selectedGroup != nil) { showAddTask = true }
        }
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
