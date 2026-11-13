//
//  TaskViewModel.swift
//  todoapp
//

import Foundation
import SwiftData

@MainActor
struct TaskViewModel {
    let modelContext: ModelContext

    func toggleComplete(_ task: TodoTask) {
        task.isCompleted.toggle()
        task.completedDate = task.isCompleted ? Date() : nil
        task.updatedDate = Date()

        if task.isCompleted, task.isRepeating, let nextDate = task.nextRepeatDate {
            let newTask = TodoTask(
                title: task.title,
                memo: task.memo,
                memoDisplayMode: task.memoDisplayMode,
                dueDate: nextDate,
                isRepeating: true,
                repeatInterval: task.repeatIntervalEnum,
                group: task.group,
                subgroup: task.subgroup
            )
            modelContext.insert(newTask)
        }
    }

    func delete(_ task: TodoTask) {
        modelContext.delete(task)
    }

    func addTask(
        title: String,
        memo: String,
        memoDisplayMode: Int,
        dueDate: Date?,
        repeatInterval: RepeatInterval,
        group: TodoGroup?,
        subgroup: SubGroup?
    ) {
        let task = TodoTask(
            title: title,
            memo: memo,
            memoDisplayMode: memoDisplayMode,
            dueDate: dueDate,
            isRepeating: repeatInterval != .none,
            repeatInterval: repeatInterval,
            group: group,
            subgroup: subgroup
        )
        modelContext.insert(task)
    }

    func updateTask(
        _ task: TodoTask,
        title: String,
        memo: String,
        memoDisplayMode: Int,
        dueDate: Date?,
        repeatInterval: RepeatInterval,
        subgroup: SubGroup?
    ) {
        task.title = title
        task.memo = memo
        task.memoDisplayMode = memoDisplayMode
        task.dueDate = dueDate
        task.isRepeating = repeatInterval != .none
        task.repeatInterval = repeatInterval == .none ? nil : repeatInterval.rawValue
        task.subgroup = subgroup
        task.updatedDate = Date()
    }
}
