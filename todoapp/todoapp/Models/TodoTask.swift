//
//  TodoTask.swift
//  todoapp
//

import Foundation
import SwiftData

enum RepeatInterval: String, CaseIterable, Identifiable, Hashable {
    case none = "none"
    case daily = "1day"
    case every3Days = "3days"
    case weekly = "1week"
    case biweekly = "2weeks"
    case monthly = "1month"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "繰り返しなし"
        case .daily: return "毎日"
        case .every3Days: return "3日ごと"
        case .weekly: return "1週間ごと"
        case .biweekly: return "2週間ごと"
        case .monthly: return "1ヶ月ごと"
        }
    }

    /// `base` の次の期限。繰り返しなしなら nil
    func nextDate(after base: Date, calendar: Calendar = .current) -> Date? {
        switch self {
        case .none: return nil
        case .daily: return calendar.date(byAdding: .day, value: 1, to: base)
        case .every3Days: return calendar.date(byAdding: .day, value: 3, to: base)
        case .weekly: return calendar.date(byAdding: .day, value: 7, to: base)
        case .biweekly: return calendar.date(byAdding: .day, value: 14, to: base)
        case .monthly: return calendar.date(byAdding: .month, value: 1, to: base)
        }
    }
}

@Model
final class TodoTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var memo: String
    var memoDisplayMode: Int
    var isCompleted: Bool
    var completedDate: Date?
    var dueDate: Date?
    var isRepeating: Bool
    var repeatInterval: String?
    var createdDate: Date
    var updatedDate: Date

    var group: TodoGroup?
    var subgroup: SubGroup?

    init(
        title: String,
        memo: String = "",
        memoDisplayMode: Int = 0,
        dueDate: Date? = nil,
        isRepeating: Bool = false,
        repeatInterval: RepeatInterval = .none,
        group: TodoGroup?,
        subgroup: SubGroup? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.memo = memo
        self.memoDisplayMode = memoDisplayMode
        self.isCompleted = false
        self.completedDate = nil
        self.dueDate = dueDate
        self.isRepeating = isRepeating
        self.repeatInterval = repeatInterval == .none ? nil : repeatInterval.rawValue
        self.createdDate = Date()
        self.updatedDate = Date()
        self.group = group
        self.subgroup = subgroup
    }
}

extension TodoTask {
    var displayDate: String {
        guard let dueDate else { return "" }
        return DateFormatter.localizedString(from: dueDate, dateStyle: .short, timeStyle: .none)
    }

    var repeatIntervalEnum: RepeatInterval {
        RepeatInterval(rawValue: repeatInterval ?? "none") ?? .none
    }

    /// 完了日（未完了なら現在時刻）を基準に次回の期限を計算する。
    var nextRepeatDate: Date? {
        guard isRepeating else { return nil }
        return repeatIntervalEnum.nextDate(after: completedDate ?? Date())
    }
}
