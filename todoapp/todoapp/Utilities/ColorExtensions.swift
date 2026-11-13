//
//  ColorExtensions.swift
//  todoapp
//

import SwiftUI
import Foundation

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)

        let r = (int >> 16) & 0xFF
        let g = (int >> 8) & 0xFF
        let b = int & 0xFF

        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1.0)
    }
}

/// 以前のテーマ（淡い 8 色）。保存済みグループの色を新しい差し色へ移し替えるときだけ使う。
enum AppTheme: String, CaseIterable, Identifiable {
    case lavender, mint, peach, sky, lemon, rose, sage, coral

    var id: String { rawValue }

    var colorHex: String {
        switch self {
        case .lavender: return "#E8E2F5"
        case .mint: return "#D4F1E4"
        case .peach: return "#F5D5CC"
        case .sky: return "#D6E8F7"
        case .lemon: return "#FFF4CC"
        case .rose: return "#F5D9E6"
        case .sage: return "#E0E8D8"
        case .coral: return "#F5D6CE"
        }
    }

    var displayName: String {
        switch self {
        case .lavender: return "Lavender"
        case .mint: return "Mint"
        case .peach: return "Peach"
        case .sky: return "Sky"
        case .lemon: return "Lemon"
        case .rose: return "Rose"
        case .sage: return "Sage"
        case .coral: return "Coral"
        }
    }

    var color: Color { Color(hex: colorHex) }
}
