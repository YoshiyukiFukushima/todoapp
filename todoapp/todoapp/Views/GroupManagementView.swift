//
//  GroupManagementView.swift
//  todoapp
//
//  左から出るグループ管理パネル（並び替え・編集・削除・追加）。
//

import SwiftUI

struct GroupManagementView: View {
    let groups: [TodoGroup]
    let groupViewModel: GroupViewModel
    @Binding var isPresented: Bool

    @State private var editingGroup: TodoGroup?
    @State private var showAddGroup = false
    @State private var groupPendingDelete: TodoGroup?
    @State private var showDeleteConfirm = false
    @Environment(\.dsAccent) private var accent

    private var sortedGroups: [TodoGroup] {
        groups.sorted(by: { $0.order < $1.order })
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                // パネルの外をタップしたら閉じる
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture(perform: close)

                sidePanel(proxy: proxy)
            }
            .ignoresSafeArea()
            .sheet(item: $editingGroup) { group in
                GroupEditSheet(group: group, groupViewModel: groupViewModel)
                    .dsRoot(accent: accent)
            }
            .sheet(isPresented: $showAddGroup) {
                GroupEditSheet(group: nil, groupViewModel: groupViewModel, nextOrder: groups.count)
                    .dsRoot(accent: accent)
            }
            .confirmDelete(isPresented: $showDeleteConfirm) {
                if let group = groupPendingDelete {
                    groupViewModel.deleteGroup(group)
                }
            }
        }
    }

    private func close() {
        withAnimation(DS.Motion.standard) { isPresented = false }
    }

    private func sidePanel(proxy: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider().overlay(DS.Colors.separator)
            groupList
                .padding(.bottom, proxy.safeAreaInsets.bottom)
        }
        .safeAreaInset(edge: .top) {
            GroupManagementHeader(onClose: close)
                .background(DS.Colors.surfaceElevated)
                .padding(.top, proxy.safeAreaInsets.top)
        }
        .frame(width: proxy.size.width * DS.Layout.sidePanelWidthRatio, height: proxy.size.height, alignment: .top)
        .background(DS.Colors.surfaceElevated)
        .dsShadow(.floating)
    }

    private var groupList: some View {
        List {
            ForEach(sortedGroups) { group in
                GroupManagementRow(
                    group: group,
                    onEdit: { editingGroup = group },
                    onDelete: {
                        groupPendingDelete = group
                        showDeleteConfirm = true
                    }
                )
                .groupManagementListRow()
            }
            .onMove(perform: moveGroups)

            AddGroupButton { showAddGroup = true }
                .padding(.top, DS.Spacing.s)
                .groupManagementListRow()
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active))
    }

    private func moveGroups(from source: IndexSet, to destination: Int) {
        var reordered = sortedGroups
        reordered.move(fromOffsets: source, toOffset: destination)
        groupViewModel.reorderGroups(reordered)
    }
}

private extension View {
    func groupManagementListRow() -> some View {
        listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: DS.Spacing.xs, leading: DS.Spacing.l, bottom: DS.Spacing.xs, trailing: DS.Spacing.l))
    }
}

/// 「グループ管理」と閉じるボタン
private struct GroupManagementHeader: View {
    let onClose: () -> Void

    var body: some View {
        HStack {
            Text("グループ管理")
                .font(DS.Typography.sectionTitle)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(DS.Typography.icon)
            }
        }
        .padding(.horizontal, DS.Spacing.l)
        .padding(.top, DS.Spacing.xs)
    }
}

/// グループ 1 行（絵文字・名前・編集・削除）
private struct GroupManagementRow: View {
    let group: TodoGroup
    let onEdit: () -> Void
    let onDelete: () -> Void

    @Environment(\.dsAccent) private var accent

    var body: some View {
        HStack {
            Text(group.icon)
            Text(group.name)
                .font(DS.Typography.taskTitle)
            Spacer()
            Button("編集", action: onEdit)
                .buttonStyle(.bordered)
                .foregroundStyle(accent.text)
            Button("削除", action: onDelete)
                .buttonStyle(.bordered)
                .tint(DS.Colors.danger)
                .foregroundStyle(DS.Colors.danger)
        }
        .padding(DS.Spacing.l)
        .background(DS.Colors.background, in: RoundedRectangle(cornerRadius: DS.Radius.m))
    }
}

/// 「＋ 新規グループ」
private struct AddGroupButton: View {
    let action: () -> Void

    @Environment(\.dsAccent) private var accent

    var body: some View {
        Button(action: action) {
            Label("新規グループ", systemImage: "plus")
                .font(DS.Typography.button)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .foregroundStyle(accent.text)
    }
}
