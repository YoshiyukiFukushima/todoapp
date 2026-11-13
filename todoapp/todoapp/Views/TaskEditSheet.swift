//
//  TaskEditSheet.swift
//  todoapp
//
//  タスクの追加（小さなシート＋「詳しく」）と詳細（全項目）。
//

import SwiftUI

struct TaskEditSheet: View {
    let group: TodoGroup?
    let subgroup: SubGroup?
    let task: TodoTask?
    let taskViewModel: TaskViewModel
    /// 追加のときの期限の初期値（見ているタブに合わせて決める。docs/design.md）
    var defaultDueDate: Date? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dsAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var title: String = ""
    @State private var memo: String = ""
    @State private var memoDisplayMode: Int = 0
    @State private var dueChoice: DueChoice = .none
    @State private var customDate: Date = Date()
    @State private var showDatePicker = false
    @State private var repeatInterval: RepeatInterval = .none
    @State private var selectedSubgroupID: UUID?
    @State private var isExpanded = false
    @State private var detent: PresentationDetent = .medium
    @State private var showDeleteConfirm = false
    @State private var originalDueDate: Date?
    @FocusState private var titleFocused: Bool

    private var isNew: Bool { task == nil }

    private var subgroups: [SubGroup] {
        (task?.group ?? group)?.subgroups.sorted(by: { $0.order < $1.order }) ?? []
    }

    private var selectedSubgroup: SubGroup? {
        subgroups.first { $0.id == selectedSubgroupID }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.l) {
                    titleField
                    dueSection
                    optionsSection

                    if isExpanded {
                        memoSection
                        if !isNew { deleteButton }
                    } else {
                        moreButton
                    }
                }
                .padding(DS.Spacing.screenMargin)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(DS.Colors.background)
            .navigationTitle(isNew ? "タスクを追加" : "タスクの詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: save) {
                        Text("保存").foregroundStyle(accent.onFill)
                    }
                        .buttonStyle(.glassProminent)
                        .tint(accent.fill)
                        .disabled(!canSave)
                        // 目立つガラスのボタンは無効でも見た目が変わらないため、薄くして示す
                        .opacity(canSave ? 1 : DS.Opacity.disabled)
                }
            }
        }
        .presentationDetents(isNew ? [.medium, .large] : [.large], selection: $detent)
        .presentationDragIndicator(.visible)
        // 色ではなくビューで渡す（シートの外枠ではテーマの環境値が届かず、モノクロにならないため）
        .presentationBackground { DS.Colors.background }
        .onAppear(perform: loadInitialValues)
        .confirmDelete(isPresented: $showDeleteConfirm) {
            if let task {
                taskViewModel.delete(task)
            }
            dismiss()
        }
    }

    // MARK: - タイトル

    private var titleField: some View {
        TextField("やること", text: $title, axis: .vertical)
            .font(DS.Typography.inputTitle)
            .foregroundStyle(DS.Colors.textPrimary)
            .focused($titleFocused)
            .submitLabel(.done)
            .padding(DS.Spacing.l)
            .background(DS.Colors.surface, in: RoundedRectangle(cornerRadius: DS.Radius.l))
            .accessibilityLabel("タスク名")
    }

    // MARK: - 期限

    private var dueSection: some View {
        SheetCard("期限") {
            HStack(spacing: DS.Spacing.s) {
                ChoiceChip(title: "今日", isSelected: dueChoice == .today) { selectDue(.today) }
                ChoiceChip(title: "明日", isSelected: dueChoice == .tomorrow) { selectDue(.tomorrow) }
                ChoiceChip(
                    title: dueChoice.isCustom ? TaskQuery().shortDateText(customDate) : "日付",
                    systemImage: "calendar",
                    isSelected: dueChoice.isCustom
                ) {
                    // カレンダーを開くだけ。選んだ日が今日・明日ならそのチップが選ばれる
                    customDate = dueChoice.resolvedDate() ?? Date()
                    withAnimation(DS.Motion.respecting(reduceMotion)) {
                        showDatePicker.toggle()
                        if showDatePicker { detent = .large }
                    }
                }
                ChoiceChip(title: "なし", isSelected: dueChoice == .none) { selectDue(.none) }
            }

            if showDatePicker {
                DatePicker("期限", selection: $customDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .environment(\.locale, Locale(identifier: "ja_JP"))
                    .tint(accent.fill)
                    .padding(DS.Spacing.s)
                    .background(DS.Colors.surface, in: RoundedRectangle(cornerRadius: DS.Radius.l))
                    .onChange(of: customDate) { _, newValue in dueChoice = DueChoice(date: newValue) }
                    .transition(.opacity)
            }
        }
    }

    private func selectDue(_ choice: DueChoice) {
        dueChoice = choice
        if !choice.isCustom {
            withAnimation(DS.Motion.respecting(reduceMotion)) { showDatePicker = false }
        }
    }

    // MARK: - 繰り返し・サブグループ

    private var optionsSection: some View {
        HStack(spacing: DS.Spacing.s) {
            Menu {
                Picker("繰り返し", selection: $repeatInterval) {
                    ForEach(RepeatInterval.allCases) { interval in
                        Text(interval.displayName).tag(interval)
                    }
                }
            } label: {
                ChipLabel(title: repeatInterval.displayName, systemImage: "repeat",
                          isSelected: repeatInterval != .none)
            }
            .accessibilityLabel("繰り返し")
            .accessibilityValue(repeatInterval.displayName)

            if !subgroups.isEmpty {
                Menu {
                    Picker("サブグループ", selection: $selectedSubgroupID) {
                        Text("サブグループなし").tag(UUID?.none)
                        ForEach(subgroups) { subgroup in
                            Text(subgroup.name).tag(Optional(subgroup.id))
                        }
                    }
                } label: {
                    ChipLabel(title: selectedSubgroup?.name ?? "サブグループなし",
                              systemImage: "list.bullet.indent",
                              isSelected: selectedSubgroup != nil)
                }
                .accessibilityLabel("サブグループ")
                .accessibilityValue(selectedSubgroup?.name ?? "なし")
            }
        }
    }

    // MARK: - 詳しく（メモ）

    private var moreButton: some View {
        Button {
            withAnimation(DS.Motion.respecting(reduceMotion)) {
                isExpanded = true
                detent = .large
            }
        } label: {
            HStack(spacing: DS.Spacing.xs) {
                Text("詳しく")
                Image(systemName: "chevron.down")
                    .imageScale(.small)
            }
            .font(DS.Typography.meta)
            .foregroundStyle(accent.text)
            .frame(maxWidth: .infinity, minHeight: DS.Size.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("メモなどの項目を表示する")
    }

    private var memoSection: some View {
        SheetCard("メモ") {
            TextEditor(text: $memo)
                .font(DS.Typography.body)
                .frame(minHeight: DS.Layout.memoEditorMinHeight)
                .scrollContentBackground(.hidden)
                .padding(DS.Spacing.s)
                .background(DS.Colors.surface, in: RoundedRectangle(cornerRadius: DS.Radius.l))
                .overlay(alignment: .topLeading) {
                    if memo.isEmpty {
                        Text("メモ（任意）")
                            .font(DS.Typography.body)
                            .foregroundStyle(DS.Colors.textTertiary)
                            .padding(.horizontal, DS.Spacing.m + DS.Spacing.xxs)
                            .padding(.vertical, DS.Spacing.m + DS.Spacing.xxs)
                            .allowsHitTesting(false)
                    }
                }
                .accessibilityLabel("メモ")

            Text("一覧でのメモの見せ方")
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Colors.textSecondary)
                .padding(.top, DS.Spacing.xs)
            Picker("一覧でのメモの見せ方", selection: $memoDisplayMode) {
                Text("出さない").tag(0)
                Text("1行だけ").tag(1)
                Text("全文").tag(2)
            }
            .pickerStyle(.segmented)
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            Label("このタスクを削除", systemImage: "trash")
                .font(DS.Typography.button)
                .foregroundStyle(DS.Colors.danger)
                .frame(maxWidth: .infinity, minHeight: DS.Size.minTapTarget)
                .background(DS.Colors.dangerSoft, in: RoundedRectangle(cornerRadius: DS.Radius.l))
        }
        .buttonStyle(.plain)
        .padding(.top, DS.Spacing.l)
    }

    // MARK: - 読み込み・保存

    private func loadInitialValues() {
        if let task {
            title = task.title
            memo = task.memo
            memoDisplayMode = task.memoDisplayMode
            dueChoice = DueChoice(date: task.dueDate)
            originalDueDate = task.dueDate
            customDate = task.dueDate ?? Date()
            repeatInterval = task.repeatIntervalEnum
            selectedSubgroupID = task.subgroup?.id
            isExpanded = true
            detent = .large
        } else {
            dueChoice = DueChoice(date: defaultDueDate)
            customDate = defaultDueDate ?? Date()
            selectedSubgroupID = subgroup?.id
            titleFocused = true
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // 期限を変えていなければ元の日時のまま（同じ日の中の並び順を変えないため）
        let unchanged = !isNew && DueChoice(date: originalDueDate) == dueChoice
        let finalDueDate = unchanged ? originalDueDate : dueChoice.resolvedDate()
        if let task {
            taskViewModel.updateTask(
                task,
                title: trimmed,
                memo: memo,
                memoDisplayMode: memoDisplayMode,
                dueDate: finalDueDate,
                repeatInterval: repeatInterval,
                subgroup: selectedSubgroup
            )
        } else {
            taskViewModel.addTask(
                title: trimmed,
                memo: memo,
                memoDisplayMode: memoDisplayMode,
                dueDate: finalDueDate,
                repeatInterval: repeatInterval,
                group: group,
                subgroup: selectedSubgroup
            )
        }
        dismiss()
    }
}
