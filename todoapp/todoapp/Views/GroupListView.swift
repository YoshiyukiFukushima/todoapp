//
//  GroupListView.swift
//  todoapp
//

import SwiftUI

struct GroupListView: View {
    let groups: [TodoGroup]
    @Binding var selectedGroupID: UUID?
    let onMenuTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: DS.Spacing.m) {
                    ForEach(groups) { group in
                        GroupIconView(group: group, isSelected: group.id == selectedGroupID)
                            .onTapGesture { selectedGroupID = group.id }
                    }
                }
                .padding(.top, DS.Spacing.m)
                .padding(.horizontal, DS.Spacing.s)
            }

            Spacer(minLength: 0)

            Button(action: onMenuTap) {
                Image(systemName: "line.3.horizontal")
                    .font(DS.Typography.icon)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .frame(width: DS.Size.minTapTarget, height: DS.Size.minTapTarget)
            }
            .padding(.bottom, DS.Spacing.m)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Colors.surfaceSunken)
    }
}
