//
//  SubGroup.swift
//  todoapp
//

import Foundation
import SwiftData

@Model
final class SubGroup {
    @Attribute(.unique) var id: UUID
    var name: String
    var order: Int
    var isExpanded: Bool
    var createdDate: Date

    var group: TodoGroup?

    @Relationship(deleteRule: .cascade, inverse: \TodoTask.subgroup)
    var tasks: [TodoTask] = []

    init(name: String, order: Int, group: TodoGroup? = nil) {
        self.id = UUID()
        self.name = name
        self.order = order
        self.isExpanded = true
        self.createdDate = Date()
        self.group = group
    }
}
