//
//  GroupSidebar.swift
//  todoapp
//
//  左のグループサイドバー。
//  閉じているとき：アイコンだけの細い列（GroupRail）
//  開いたとき：名前・件数が見え、並べ替え・編集・削除・追加ができるパネル（GroupSidebarPanel）
//

import SwiftUI

/// サイドバーの開閉ボタン
private struct SidebarToggleButton: View {
    let isOpen: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "sidebar.left")
                .font(DS.Typography.icon)
                .foregroundStyle(DS.Colors.textSecondary)
                .frame(width: DS.Size.minTapTarget, height: DS.Size.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOpen ? "グループ一覧を閉じる" : "グループ一覧を開く")
    }
}

// MARK: - 閉じたとき

struct GroupRail: View {
    let groups: [TodoGroup]
    let selectedGroupID: UUID?
    let onToggle: () -> Void
    let onSelect: (TodoGroup) -> Void

    var body: some View {
        VStack(spacing: DS.Spacing.s) {
            SidebarToggleButton(isOpen: false, action: onToggle)

            ScrollView {
                VStack(spacing: DS.Spacing.m) {
                    ForEach(groups) { group in
                        let isSelected = group.id == selectedGroupID
                        Button { onSelect(group) } label: {
                            GroupAvatar(group: group, isSelected: isSelected)
                                .overlay(alignment: .topTrailing) {
                                    CountBadge(count: group.incompleteTaskCount)
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(group.name)
                        .accessibilityValue(group.incompleteTaskCount > 0 ? "未完了\(group.incompleteTaskCount)件" : "")
                        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                    }
                }
                .padding(.vertical, DS.Spacing.xs)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.top, DS.Spacing.s)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(DS.Colors.surfaceSunken.ignoresSafeArea())
    }
}

// MARK: - 開いたとき

struct GroupSidebarPanel: View {
    let groups: [TodoGroup]
    let selectedGroupID: UUID?
    let onClose: () -> Void
    let onSelect: (TodoGroup) -> Void
    let onAdd: () -> Void
    let onEdit: (TodoGroup) -> Void
    let onDelete: (TodoGroup) -> Void
    let onMove: (IndexSet, Int) -> Void

    @Environment(\.dsAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 並べ替えモード（件数の代わりに ≡ を出す）
    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            HStack(spacing: 0) {
                SidebarToggleButton(isOpen: true, action: onClose)
                    .padding(.horizontal, (DS.Size.sidebarCollapsed - DS.Size.minTapTarget) / 2)
                Text("グループ")
                    .font(DS.Typography.sectionTitle)
                    .foregroundStyle(DS.Colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: DS.Spacing.s)
                Button {
                    withAnimation(DS.Motion.respecting(reduceMotion)) { isEditing.toggle() }
                } label: {
                    Text(isEditing ? "完了" : "編集")
                        .font(isEditing ? DS.Typography.button : DS.Typography.meta)
                        .foregroundStyle(accent.text)
                        .padding(.horizontal, DS.Spacing.m)
                        .frame(minHeight: DS.Size.minTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint(isEditing ? "並べ替えを終える" : "グループを並べ替える")
                .padding(.trailing, DS.Spacing.s)
            }

            List {
                ForEach(groups) { group in
                    row(for: group)
                }
                // 並べ替えは編集中だけ（長押しは編集・削除のメニュー）
                .onMove(perform: isEditing ? onMove : nil)

                if !isEditing {
                Button(action: onAdd) {
                    Label("新規グループ", systemImage: "plus")
                        .font(DS.Typography.button)
                        .foregroundStyle(accent.text)
                        .frame(maxWidth: .infinity, minHeight: DS.Size.minTapTarget, alignment: .leading)
                        .padding(.leading, DS.Spacing.l)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: DS.Spacing.s, leading: DS.Spacing.s, bottom: DS.Spacing.s, trailing: DS.Spacing.s))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
        }
        .padding(.top, DS.Spacing.s)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(DS.Colors.surfaceSunken.ignoresSafeArea())
        .dsShadow(.floating)
    }

    @ViewBuilder
    private func row(for group: TodoGroup) -> some View {
        Group {
            if isEditing {
                editingRow(for: group)
            } else {
                normalRow(for: group)
            }
        }
        .listRowInsets(EdgeInsets(top: DS.Spacing.xs + DS.Spacing.xxs, leading: DS.Spacing.s, bottom: DS.Spacing.xs + DS.Spacing.xxs, trailing: DS.Spacing.s))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    /// ふだん：タップで切り替え、長押しで編集・削除のメニュー
    private func normalRow(for group: TodoGroup) -> some View {
        let isSelected = group.id == selectedGroupID
        let count = group.incompleteTaskCount
        return Button { onSelect(group) } label: {
            HStack(spacing: DS.Spacing.s) {
                GroupAvatar(group: group, isSelected: isSelected)
                Text(group.name)
                    .font(isSelected ? DS.Typography.taskTitle : DS.Typography.body)
                    .foregroundStyle(DS.Colors.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: DS.Spacing.s)
                if count > 0 {
                    Text("\(count)")
                        .font(DS.Typography.counter)
                        .foregroundStyle(DS.Colors.textSecondary)
                }
            }
            .padding(.trailing, DS.Spacing.m)
            // 選択中の白い帯。listRowBackground は並べ替え後に古い行に残るため、行の中に描く
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.xl)
                    .fill(isSelected ? DS.Colors.surface : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("編集", systemImage: "pencil") { onEdit(group) }
            Button("削除", systemImage: "trash", role: .destructive) { onDelete(group) }
                .tint(DS.Colors.danger)
        }
        .accessibilityLabel(group.name)
        .accessibilityValue(count > 0 ? "未完了\(count)件" : "")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityAction(named: "編集") { onEdit(group) }
        .accessibilityAction(named: "削除") { onDelete(group) }
    }

    /// 編集中：左端に ⊖（削除）、右に ✎（編集）。その右にシステムの ≡（並べ替え）が出る。
    /// 削除と ≡ を離して置き、押し間違いを防ぐ（docs/design.md）
    private func editingRow(for group: TodoGroup) -> some View {
        HStack(spacing: DS.Spacing.xs) {
            Button { onDelete(group) } label: {
                Image(systemName: "minus.circle.fill")
                    .font(DS.Typography.icon)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(DS.Colors.onDanger, DS.Colors.danger)
                    .frame(width: DS.Size.compactTapWidth, height: DS.Size.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(group.name)を削除")

            GroupAvatar(group: group, isSelected: false, size: DS.Size.groupIconCompact)
                .accessibilityHidden(true)
            Text(group.name)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colors.textPrimary)
                .lineLimit(1)
            Spacer(minLength: DS.Spacing.xs)

            Button { onEdit(group) } label: {
                Image(systemName: "pencil")
                    .font(DS.Typography.icon)
                    .foregroundStyle(accent.text)
                    .frame(width: DS.Size.compactTapWidth, height: DS.Size.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(group.name)を編集")
        }
        .transition(.opacity)
    }
}
