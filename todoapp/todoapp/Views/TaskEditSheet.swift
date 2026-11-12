//
//  TaskEditSheet.swift
//  todoapp
//

import SwiftUI

struct TaskEditSheet: View {
    let group: TodoGroup?
    let subgroup: SubGroup?
    let task: TodoTask?
    let taskViewModel: TaskViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var memo: String = ""
    @State private var memoDisplayMode: Int = 0
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    @State private var repeatInterval: RepeatInterval = .none
    @State private var showDeleteConfirm = false
    @State private var selectedSubgroupID: UUID?

    /// このタスクのグループにあるサブグループ（並び順）
    private var subgroups: [SubGroup] {
        (task?.group ?? group)?.subgroups.sorted(by: { $0.order < $1.order }) ?? []
    }

    private var selectedSubgroup: SubGroup? {
        subgroups.first { $0.id == selectedSubgroupID }
    }

    var body: some View {
        NavigationStack {
            Form {
                DSFormSection("タスク名") {
                    TextField("タスク名", text: $title)
                }

                if !subgroups.isEmpty {
                    DSFormSection("サブグループ") {
                        Picker("サブグループ", selection: $selectedSubgroupID) {
                            Text("なし").tag(UUID?.none)
                            ForEach(subgroups) { subgroup in
                                Text(subgroup.name).tag(Optional(subgroup.id))
                            }
                        }
                    }
                }

                DSFormSection("メモ") {
                    TextEditor(text: $memo)
                        .frame(minHeight: DS.Layout.memoEditorMinHeight)
                        .scrollContentBackground(.hidden)
                    MemoDisplayModePicker(selection: $memoDisplayMode)
                }

                DSFormSection("期限") {
                    Toggle("期限を設定", isOn: $hasDueDate.animation(DS.Motion.standard))
                    if hasDueDate {
                        DatePicker("期限", selection: $dueDate, displayedComponents: .date)
                    }
                }

                DSFormSection("繰り返し") {
                    Picker("繰り返し", selection: $repeatInterval) {
                        ForEach(RepeatInterval.allCases) { interval in
                            Text(interval.displayName).tag(interval)
                        }
                    }
                }

                if task != nil {
                    Section {
                        Button("削除", role: .destructive) {
                            showDeleteConfirm = true
                        }
                        .foregroundStyle(DS.Colors.danger)
                    }
                    .dsFormRow()
                }
            }
            .dsFormBackground()
            .navigationTitle(task == nil ? "タスク追加" : "タスク詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear(perform: loadInitialValues)
        .confirmDelete(isPresented: $showDeleteConfirm) {
            if let task {
                taskViewModel.delete(task)
            }
            dismiss()
        }
    }

    private func loadInitialValues() {
        selectedSubgroupID = (task?.subgroup ?? subgroup)?.id
        guard let task else { return }
        title = task.title
        memo = task.memo
        memoDisplayMode = task.memoDisplayMode
        hasDueDate = task.dueDate != nil
        dueDate = task.dueDate ?? Date()
        repeatInterval = task.repeatIntervalEnum
    }

    private func save() {
        let finalDueDate = hasDueDate ? dueDate : nil
        if let task {
            taskViewModel.updateTask(
                task,
                title: title,
                memo: memo,
                memoDisplayMode: memoDisplayMode,
                dueDate: finalDueDate,
                repeatInterval: repeatInterval,
                subgroup: selectedSubgroup
            )
        } else {
            taskViewModel.addTask(
                title: title,
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

/// メモを一覧でどう見せるか（表示なし／1行／全文）
private struct MemoDisplayModePicker: View {
    @Binding var selection: Int

    var body: some View {
        Picker("メモ表示", selection: $selection) {
            Text("表示なし").tag(0)
            Text("1行表示").tag(1)
            Text("全文表示").tag(2)
        }
    }
}
