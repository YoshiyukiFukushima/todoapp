//
//  TodoGroup.swift
//  todoapp
//

import Foundation
import SwiftData

@Model
final class TodoGroup {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var order: Int
    var createdDate: Date

    @Relationship(deleteRule: .cascade, inverse: \TodoTask.group)
    var tasks: [TodoTask] = []

    @Relationship(deleteRule: .cascade, inverse: \SubGroup.group)
    var subgroups: [SubGroup] = []

    init(name: String, icon: String, colorHex: String, order: Int) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.order = order
        self.createdDate = Date()
    }
}

extension TodoGroup {
    var incompleteTaskCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }
}
