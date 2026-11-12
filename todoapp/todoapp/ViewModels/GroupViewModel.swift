//
//  GroupViewModel.swift
//  todoapp
//

import Foundation
import SwiftData

@MainActor
struct GroupViewModel {
    let modelContext: ModelContext

    func addGroup(name: String, icon: String, colorHex: String, order: Int) {
        let group = TodoGroup(name: name, icon: icon, colorHex: colorHex, order: order)
        modelContext.insert(group)
    }

    func updateGroup(_ group: TodoGroup, name: String, icon: String, colorHex: String) {
        group.name = name
        group.icon = icon
        group.colorHex = colorHex
    }

    func deleteGroup(_ group: TodoGroup) {
        modelContext.delete(group)
    }

    /// ドラッグ&ドロップ後の並び順を order フィールドへ反映して保存する
    func reorderGroups(_ orderedGroups: [TodoGroup]) {
        for (index, group) in orderedGroups.enumerated() {
            group.order = index
        }
        try? modelContext.save()
    }

    func addSubGroup(name: String, to group: TodoGroup, order: Int) {
        let subgroup = SubGroup(name: name, order: order, group: group)
        modelContext.insert(subgroup)
    }

    func updateSubGroup(_ subgroup: SubGroup, name: String) {
        subgroup.name = name
    }

    /// サブグループを削除する。keepingTasks が true なら中のタスクは「サブグループなし」に移して残す
    func deleteSubGroup(_ subgroup: SubGroup, keepingTasks: Bool) {
        if keepingTasks {
            for task in subgroup.tasks {
                task.subgroup = nil
            }
            subgroup.tasks = []
        }
        modelContext.delete(subgroup)
    }

    func toggleExpanded(_ subgroup: SubGroup) {
        subgroup.isExpanded.toggle()
    }
}
