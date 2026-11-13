//
//  TaskSheetParts.swift
//  todoapp
//
//  タスク追加・詳細シートの部品（チップ、カード）。
//

import SwiftUI

/// 期限の選び方
enum DueChoice: Equatable {
    case none
    case today
    case tomorrow
    case custom(Date)

    /// 保存するときの期限
    func resolvedDate(now: Date = Date(), calendar: Calendar = .current) -> Date? {
        switch self {
        case .none: nil
        case .today: now
        case .tomorrow: calendar.date(byAdding: .day, value: 1, to: now)
        case .custom(let date): date
        }
    }

    /// 既存の期限からチップの状態を決める
    init(date: Date?, now: Date = Date(), calendar: Calendar = .current) {
        guard let date else { self = .none; return }
        if calendar.isDate(date, inSameDayAs: now) {
            self = .today
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
                  calendar.isDate(date, inSameDayAs: tomorrow) {
            self = .tomorrow
        } else {
            self = .custom(date)
        }
    }

    var isCustom: Bool {
        if case .custom = self { return true }
        return false
    }
}

/// 丸いチップの見た目
struct ChipLabel: View {
    let title: String
    var systemImage: String?
    let isSelected: Bool

    @Environment(\.dsAccent) private var accent

    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .imageScale(.small)
            }
            Text(title)
                .lineLimit(1)
        }
        .font(DS.Typography.meta)
        .foregroundStyle(isSelected ? accent.text : DS.Colors.textSecondary)
        .padding(.horizontal, DS.Spacing.m)
        .frame(minHeight: DS.Size.minTapTarget)
        .background(isSelected ? accent.soft : DS.Colors.surface, in: Capsule())
        .overlay(
            Capsule().strokeBorder(isSelected ? accent.fill : DS.Colors.separator, lineWidth: DS.Stroke.hairline * 2)
        )
        .contentShape(Capsule())
    }
}

/// タップで選ぶチップ
struct ChoiceChip: View {
    let title: String
    var systemImage: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ChipLabel(title: title, systemImage: systemImage, isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// 見出しつきのカード（シートの中の区切り）
struct SheetCard<Content: View>: View {
    var title: String?
    let content: Content

    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            if let title {
                Text(title)
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .accessibilityAddTraits(.isHeader)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
