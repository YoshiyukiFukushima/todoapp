//
//  SubGroupHeaderView.swift
//  todoapp
//

import SwiftUI

struct SubGroupHeaderView: View {
    let subgroup: SubGroup
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: DS.Spacing.s) {
            Image(systemName: subgroup.isExpanded ? "chevron.down" : "chevron.right")
                .font(DS.Typography.iconSmall)
                .foregroundStyle(DS.Colors.textSecondary)

            Text(subgroup.name)
                .font(DS.Typography.sectionTitle)
                .foregroundStyle(DS.Colors.textPrimary)

            Text("(\(subgroup.tasks.count))")
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Colors.textSecondary)

            Spacer()
        }
        .padding(.vertical, DS.Spacing.s)
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
    }
}
