//
//  GroupAppearance.swift
//  todoapp
//
//  グループの見た目（アイコンと色）を、保存データから決める。
//  保存データ（絵文字・淡い色の hex）はまだ書き換えず、表示のときだけ新しい形に読み替える。
//  データの移し替えはグループ編集画面で行う（docs/design.md）。
//

import SwiftUI
import UIKit

/// グループのアイコンに何を出すか
enum GroupGlyph: Equatable {
    case symbol(String)
    case letter(String)
}

enum GroupAppearance {
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
        if let theme = AppTheme.allCases.first(where: { $0.colorHex.uppercased() == normalized }) {
            return theme.accent
        }
        return nearestAccent(to: UIColor(Color(hex: colorHex)))
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
