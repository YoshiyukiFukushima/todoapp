//
//  GroupAppearance.swift
//  todoapp
//
//  グループの見た目（アイコンと色）を、保存データから決める。
//  以前の保存データ（絵文字・淡い色の hex）は、起動時に `migrateLegacyGroups` で新しい形に書き換える。
//  書き換え前のデータが残っていても、表示のときに同じ対応で読み替える（docs/design.md）。
//

import SwiftUI
import UIKit

/// グループのアイコンに何を出すか
enum GroupGlyph: Equatable {
    case symbol(String)
    case letter(String)
}

enum GroupAppearance {
    /// グループ編集で選べるアイコン（SF Symbols 24 個）
    static let iconChoices: [String] = [
        "house.fill", "briefcase.fill", "cart.fill", "fork.knife",
        "book.fill", "graduationcap.fill", "dumbbell.fill", "figure.run",
        "heart.fill", "star.fill", "leaf.fill", "pawprint.fill",
        "car.fill", "airplane", "gift.fill", "banknote.fill",
        "paintpalette.fill", "music.note", "gamecontroller.fill", "camera.fill",
        "wrench.and.screwdriver.fill", "bubbles.and.sparkles.fill", "pills.fill", "target",
    ]

    /// アイコンの読み上げ用の名前
    static let iconNames: [String: String] = [
        "house.fill": "家", "briefcase.fill": "仕事かばん", "cart.fill": "買い物かご", "fork.knife": "食事",
        "book.fill": "本", "graduationcap.fill": "学び", "dumbbell.fill": "筋トレ", "figure.run": "ランニング",
        "heart.fill": "ハート", "star.fill": "星", "leaf.fill": "葉っぱ", "pawprint.fill": "ペット",
        "car.fill": "車", "airplane": "旅行", "gift.fill": "プレゼント", "banknote.fill": "お金",
        "paintpalette.fill": "絵の具", "music.note": "音楽", "gamecontroller.fill": "ゲーム", "camera.fill": "カメラ",
        "wrench.and.screwdriver.fill": "工具", "bubbles.and.sparkles.fill": "掃除", "pills.fill": "薬", "target": "目標",
    ]

    /// 保存用の icon 値：SF Symbol 名、または空（＝名前の 1 文字目を表示）
    static let letterIcon = ""

    /// 以前のアイコン候補（絵文字）→ 近い SF Symbol
    static let legacyEmojiSymbols: [String: String] = [
        "🏠": "house.fill",
        "📝": "note.text",
        "🛒": "cart.fill",
        "🏋️": "dumbbell.fill",
        "💼": "briefcase.fill",
        "📚": "books.vertical.fill",
        "🍽️": "fork.knife",
        "🎯": "target",
        "💰": "banknote.fill",
        "🧹": "bubbles.and.sparkles.fill",
        "🚗": "car.fill",
        "🎨": "paintpalette.fill",
        "📌": "pin.fill",
    ]

    /// アイコン：SF Symbol 名ならそのまま、以前の絵文字なら対応する Symbol、どちらでもなければ名前の 1 文字目
    static func glyph(icon: String, name: String) -> GroupGlyph {
        if let symbol = legacyEmojiSymbols[icon] {
            return .symbol(symbol)
        }
        if !icon.isEmpty, icon.allSatisfy({ $0.isASCII }), UIImage(systemName: icon) != nil {
            return .symbol(icon)
        }
        let first = name.trimmingCharacters(in: .whitespaces).first.map(String.init) ?? "?"
        return .letter(first)
    }

    /// 色：差し色の名前（例 "mikan"）ならそれ、以前のテーマの淡い色なら対応する色、
    /// それ以外（自由に選んだ色）は色相が近いものを選ぶ
    static func accent(colorHex: String) -> DS.Accent {
        if let accent = DS.Accent(rawValue: colorHex) {
            return accent
        }
        let normalized = colorHex.uppercased()
        if let legacy = AppTheme.allCases.first(where: { $0.colorHex.uppercased() == normalized }) {
            return legacyAccent(legacy)
        }
        return nearestAccent(to: UIColor(Color(hex: colorHex)))
    }

    /// 以前の淡い 8 色 → 新しい 8 色
    private static func legacyAccent(_ legacy: AppTheme) -> DS.Accent {
        switch legacy {
        case .lavender: .grape
        case .mint: .teal
        case .peach: .mikan
        case .sky: .sky
        case .lemon: .cocoa
        case .rose: .berry
        case .sage: .leaf
        case .coral: .tomato
        }
    }

    private static func nearestAccent(to color: UIColor) -> DS.Accent {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        if saturation < 0.2 { return .cocoa }

        let degrees = hue * 360
        let candidates: [(DS.Accent, CGFloat)] = [
            (.tomato, 5), (.mikan, 28), (.leaf, 115), (.teal, 172),
            (.sky, 210), (.grape, 258), (.berry, 333),
        ]
        return candidates.min { lhs, rhs in
            circularDistance(lhs.1, degrees) < circularDistance(rhs.1, degrees)
        }!.0
    }

    private static func circularDistance(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
        let d = abs(a - b).truncatingRemainder(dividingBy: 360)
        return min(d, 360 - d)
    }
}

extension TodoGroup {
    var glyph: GroupGlyph { GroupAppearance.glyph(icon: icon, name: name) }
    var accent: DS.Accent { GroupAppearance.accent(colorHex: colorHex) }
}

// MARK: - 以前のデータの移し替え

extension GroupAppearance {
    /// 以前の絵文字・淡い色で保存されたグループを、新しい形（SF Symbol 名・差し色の名前）に書き換える。
    /// 見た目は変わらない。何度呼んでも結果は同じ。書き換えた数を返す。
    @discardableResult
    static func migrateLegacyGroups(_ groups: [TodoGroup]) -> Int {
        var changed = 0
        for group in groups {
            var didChange = false

            if case .symbol(let symbol) = glyph(icon: group.icon, name: group.name) {
                if group.icon != symbol {
                    group.icon = symbol
                    didChange = true
                }
            } else if group.icon != letterIcon {
                group.icon = letterIcon
                didChange = true
            }

            let accentName = accent(colorHex: group.colorHex).rawValue
            if group.colorHex != accentName {
                group.colorHex = accentName
                didChange = true
            }

            if didChange { changed += 1 }
        }
        return changed
    }
}
