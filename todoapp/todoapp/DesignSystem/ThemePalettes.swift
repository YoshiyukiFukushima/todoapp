//
//  ThemePalettes.swift
//  todoapp
//
//  テーマごとの色の表。DS.Colors の各色は、今のテーマの表から値を取る。
//  新しいテーマの色は、ここに表を 1 つ足して ColorTheme.palette から返す。
//

import UIKit

/// ライト／ダークの 2 つの値（0xRRGGBB と不透明度）
nonisolated struct DSColorPair: Sendable {
    let light: UInt32
    let dark: UInt32
    var lightAlpha: CGFloat = 1
    var darkAlpha: CGFloat = 1

    init(_ light: UInt32, _ dark: UInt32, lightAlpha: CGFloat = 1, darkAlpha: CGFloat = 1) {
        self.light = light
        self.dark = dark
        self.lightAlpha = lightAlpha
        self.darkAlpha = darkAlpha
    }

    /// ライト／ダークで変えない色（暗さを固定するテーマ向け）
    init(fixed rgb: UInt32, alpha: CGFloat = 1) {
        self.init(rgb, rgb, lightAlpha: alpha, darkAlpha: alpha)
    }

    func resolve(isDark: Bool) -> UIColor {
        UIColor(rgb: isDark ? dark : light, alpha: isDark ? darkAlpha : lightAlpha)
    }
}

/// テーマが決める色の一覧（名前の意味は DS.Colors を参照）
nonisolated enum DSColorToken: Sendable {
    case background, surface, surfaceSunken, segmentSelected, surfaceElevated
    case textPrimary, textSecondary, textTertiary, separator, success, shadow
}

nonisolated struct ThemePalette: Sendable {
    var background: DSColorPair
    var surface: DSColorPair
    var surfaceSunken: DSColorPair
    var segmentSelected: DSColorPair
    var surfaceElevated: DSColorPair
    var textPrimary: DSColorPair
    var textSecondary: DSColorPair
    var textTertiary: DSColorPair
    var separator: DSColorPair
    var success: DSColorPair
    var shadow: DSColorPair

    subscript(token: DSColorToken) -> DSColorPair {
        switch token {
        case .background: background
        case .surface: surface
        case .surfaceSunken: surfaceSunken
        case .segmentSelected: segmentSelected
        case .surfaceElevated: surfaceElevated
        case .textPrimary: textPrimary
        case .textSecondary: textSecondary
        case .textTertiary: textTertiary
        case .separator: separator
        case .success: success
        case .shadow: shadow
        }
    }
}

nonisolated extension ThemePalette {
    /// 差し色 8 色のテーマ共通（あたたかいオフホワイト）
    static let warm = ThemePalette(
        background: DSColorPair(0xFFF7EF, 0x17120D),
        surface: DSColorPair(0xFFFFFF, 0x241D17),
        surfaceSunken: DSColorPair(0xF6E7D8, 0x2E251D),
        segmentSelected: DSColorPair(0xFFFFFF, 0x4A3D31),
        surfaceElevated: DSColorPair(0xFFFFFF, 0x2C241C),
        textPrimary: DSColorPair(0x3A2410, 0xF7EDE4),
        textSecondary: DSColorPair(0x8A6A4F, 0xBFA892),
        textTertiary: DSColorPair(0xB59A82, 0x8C7663),
        separator: DSColorPair(0xF0E2D4, 0x3A3027),
        success: DSColorPair(0x3FA34D, 0x5CC46A),
        shadow: DSColorPair(0x5C330F, 0x000000, lightAlpha: 0.10, darkAlpha: 0.45)
    )

    /// モノクロ（色味のない白・グレー・黒。100% の輪も白黒）
    static let mono = ThemePalette(
        background: DSColorPair(0xF5F5F5, 0x111111),
        surface: DSColorPair(0xFFFFFF, 0x1E1E1E),
        surfaceSunken: DSColorPair(0xEBEBEB, 0x2A2A2A),
        segmentSelected: DSColorPair(0xFFFFFF, 0x474747),
        surfaceElevated: DSColorPair(0xFFFFFF, 0x262626),
        textPrimary: DSColorPair(0x1A1A1A, 0xF2F2F2),
        textSecondary: DSColorPair(0x6B6B6B, 0xA8A8A8),
        textTertiary: DSColorPair(0xA3A3A3, 0x6E6E6E),
        separator: DSColorPair(0xE3E3E3, 0x333333),
        success: DSColorPair(0x1A1A1A, 0xF2F2F2),
        shadow: DSColorPair(0x000000, 0x000000, lightAlpha: 0.08, darkAlpha: 0.45)
    )

    /// 泡（深い青の水の中。いつも暗い）
    static let bubble = ThemePalette(
        background: DSColorPair(fixed: 0x10173A),
        surface: DSColorPair(fixed: 0x27316B),
        surfaceSunken: DSColorPair(fixed: 0x1A2352),
        segmentSelected: DSColorPair(fixed: 0x3A468C),
        surfaceElevated: DSColorPair(fixed: 0x1E275A),
        textPrimary: DSColorPair(fixed: 0xF3F5FF),
        textSecondary: DSColorPair(fixed: 0xB3BCE8),
        textTertiary: DSColorPair(fixed: 0x7C86BC),
        separator: DSColorPair(fixed: 0x323C78),
        success: DSColorPair(fixed: 0x5FD8A8),
        shadow: DSColorPair(fixed: 0x000000, alpha: 0.5)
    )
}

nonisolated extension UIColor {
    convenience init(rgb: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: alpha
        )
    }
}
