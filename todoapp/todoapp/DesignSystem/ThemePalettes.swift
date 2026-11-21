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

nonisolated extension ThemePalette {
    /// 桜（夜桜の庭。藤色のすりガラス。いつも暗い）
    static let sakura = ThemePalette(
        background: DSColorPair(fixed: 0x1D1322),
        surface: DSColorPair(fixed: 0x4B3656),
        surfaceSunken: DSColorPair(fixed: 0x2C1F33),
        segmentSelected: DSColorPair(fixed: 0x5F4570),
        surfaceElevated: DSColorPair(fixed: 0x33243C),
        textPrimary: DSColorPair(fixed: 0xFFF5F9),
        textSecondary: DSColorPair(fixed: 0xDCC3D3),
        textTertiary: DSColorPair(fixed: 0x9E8295),
        separator: DSColorPair(fixed: 0x48344F),
        success: DSColorPair(fixed: 0xF5C76A),
        shadow: DSColorPair(fixed: 0x000000, alpha: 0.5)
    )

    /// 判子（和紙。いつも明るい）
    static let stamp = ThemePalette(
        background: DSColorPair(fixed: 0xE9E0CF),
        surface: DSColorPair(fixed: 0xFAF6EE),
        surfaceSunken: DSColorPair(fixed: 0xDFD4BF),
        segmentSelected: DSColorPair(fixed: 0xFAF6EE),
        surfaceElevated: DSColorPair(fixed: 0xFFFDF8),
        textPrimary: DSColorPair(fixed: 0x3B3226),
        textSecondary: DSColorPair(fixed: 0x7A6D5B),
        textTertiary: DSColorPair(fixed: 0xA89B86),
        separator: DSColorPair(fixed: 0xD9CDB7),
        success: DSColorPair(fixed: 0xC2452F),
        shadow: DSColorPair(fixed: 0x6B5A3A, alpha: 0.18)
    )

    /// ろうそく（暗い部屋。いつも暗い）
    static let candle = ThemePalette(
        background: DSColorPair(fixed: 0x0C0B0F),
        surface: DSColorPair(fixed: 0x1F1D23),
        surfaceSunken: DSColorPair(fixed: 0x17161B),
        segmentSelected: DSColorPair(fixed: 0x2E2B33),
        surfaceElevated: DSColorPair(fixed: 0x1A191E),
        textPrimary: DSColorPair(fixed: 0xF7EEDF),
        textSecondary: DSColorPair(fixed: 0xBCAE9A),
        textTertiary: DSColorPair(fixed: 0x7B7266),
        separator: DSColorPair(fixed: 0x2A282F),
        success: DSColorPair(fixed: 0xF2B663),
        shadow: DSColorPair(fixed: 0x000000, alpha: 0.6)
    )

    /// 星座（夜空。いつも暗い）
    static let constellation = ThemePalette(
        background: DSColorPair(fixed: 0x080C1E),
        surface: DSColorPair(fixed: 0x1C1F33),
        surfaceSunken: DSColorPair(fixed: 0x111428),
        segmentSelected: DSColorPair(fixed: 0x2A2E48),
        surfaceElevated: DSColorPair(fixed: 0x151830),
        textPrimary: DSColorPair(fixed: 0xF1F3FF),
        textSecondary: DSColorPair(fixed: 0xAEB4D0),
        textTertiary: DSColorPair(fixed: 0x6E7494),
        separator: DSColorPair(fixed: 0x23273F),
        success: DSColorPair(fixed: 0xF5C76A),
        shadow: DSColorPair(fixed: 0x000000, alpha: 0.55)
    )

    /// 氷の結晶（雪の夜。氷のような青いガラス。いつも暗い）
    static let rikka = ThemePalette(
        background: DSColorPair(fixed: 0x0D1A3A),
        surface: DSColorPair(fixed: 0x2A4272),
        surfaceSunken: DSColorPair(fixed: 0x16264D),
        segmentSelected: DSColorPair(fixed: 0x3A5590),
        surfaceElevated: DSColorPair(fixed: 0x1B2E5A),
        textPrimary: DSColorPair(fixed: 0xF4F8FF),
        textSecondary: DSColorPair(fixed: 0xB9CCEC),
        textTertiary: DSColorPair(fixed: 0x7A8FB8),
        separator: DSColorPair(fixed: 0x2C406E),
        success: DSColorPair(fixed: 0xBFE3FF),
        shadow: DSColorPair(fixed: 0x000000, alpha: 0.5)
    )

    /// 水滴（深い水の中。青いガラス。いつも暗い）
    static let water = ThemePalette(
        background: DSColorPair(fixed: 0x0B1A36),
        surface: DSColorPair(fixed: 0x24406E),
        surfaceSunken: DSColorPair(fixed: 0x132A50),
        segmentSelected: DSColorPair(fixed: 0x34578E),
        surfaceElevated: DSColorPair(fixed: 0x183158),
        textPrimary: DSColorPair(fixed: 0xF2F8FF),
        textSecondary: DSColorPair(fixed: 0xB2CBEA),
        textTertiary: DSColorPair(fixed: 0x7590B6),
        separator: DSColorPair(fixed: 0x274470),
        success: DSColorPair(fixed: 0x8FD8FF),
        shadow: DSColorPair(fixed: 0x000000, alpha: 0.5)
    )

    /// マーガレット（夜の草原。若葉色のすりガラス。いつも暗い）
    static let margaret = ThemePalette(
        background: DSColorPair(fixed: 0x10231C),
        surface: DSColorPair(fixed: 0x2C4F40),
        surfaceSunken: DSColorPair(fixed: 0x1A3329),
        segmentSelected: DSColorPair(fixed: 0x3C6552),
        surfaceElevated: DSColorPair(fixed: 0x1F3A2F),
        textPrimary: DSColorPair(fixed: 0xF6FBF3),
        textSecondary: DSColorPair(fixed: 0xC4D9C8),
        textTertiary: DSColorPair(fixed: 0x86A391),
        separator: DSColorPair(fixed: 0x2E4D3F),
        success: DSColorPair(fixed: 0xF7C948),
        shadow: DSColorPair(fixed: 0x000000, alpha: 0.5)
    )
}

nonisolated extension ThemePalette {
    /// ねこ（夜のお部屋。ほんのり赤紫のすりガラス。いつも暗い）
    static let cat = ThemePalette(
        background: DSColorPair(fixed: 0x2B1D2A),
        surface: DSColorPair(fixed: 0x4A3548),
        surfaceSunken: DSColorPair(fixed: 0x36253A),
        segmentSelected: DSColorPair(fixed: 0x5C4459),
        surfaceElevated: DSColorPair(fixed: 0x3A2838),
        textPrimary: DSColorPair(fixed: 0xFFF7FA),
        textSecondary: DSColorPair(fixed: 0xDCC6D2),
        textTertiary: DSColorPair(fixed: 0x9F8597),
        separator: DSColorPair(fixed: 0x4A3548),
        success: DSColorPair(fixed: 0xF2A6BE),
        shadow: DSColorPair(fixed: 0x000000, alpha: 0.5)
    )

    /// 花火（夏の夜空。墨色のガラス。いつも暗い）
    static let fireworks = ThemePalette(
        background: DSColorPair(fixed: 0x05070F),
        surface: DSColorPair(fixed: 0x1D1F2B),
        surfaceSunken: DSColorPair(fixed: 0x12141E),
        segmentSelected: DSColorPair(fixed: 0x2C2F40),
        surfaceElevated: DSColorPair(fixed: 0x171925),
        textPrimary: DSColorPair(fixed: 0xF4F5FA),
        textSecondary: DSColorPair(fixed: 0xB4B7C8),
        textTertiary: DSColorPair(fixed: 0x787C91),
        separator: DSColorPair(fixed: 0x262938),
        success: DSColorPair(fixed: 0xF5C77A),
        shadow: DSColorPair(fixed: 0x000000, alpha: 0.6)
    )

    /// ひよこ（あたたかい明かりの部屋。こはく色のガラス。いつも暗い）
    static let chick = ThemePalette(
        background: DSColorPair(fixed: 0x1F1910),
        surface: DSColorPair(fixed: 0x4A4030),
        surfaceSunken: DSColorPair(fixed: 0x2E261A),
        segmentSelected: DSColorPair(fixed: 0x5E5240),
        surfaceElevated: DSColorPair(fixed: 0x332A1D),
        textPrimary: DSColorPair(fixed: 0xFFFAF0),
        textSecondary: DSColorPair(fixed: 0xDDD0B8),
        textTertiary: DSColorPair(fixed: 0xA0927A),
        separator: DSColorPair(fixed: 0x4A4030),
        success: DSColorPair(fixed: 0xFFD54A),
        shadow: DSColorPair(fixed: 0x000000, alpha: 0.5)
    )

    /// 風船（夕暮れの空。ラベンダーのガラス。いつも暗い）
    static let balloon = ThemePalette(
        background: DSColorPair(fixed: 0x1F2140),
        surface: DSColorPair(fixed: 0x3C3A62),
        surfaceSunken: DSColorPair(fixed: 0x2A2A4A),
        segmentSelected: DSColorPair(fixed: 0x4D4A75),
        surfaceElevated: DSColorPair(fixed: 0x2E2D52),
        textPrimary: DSColorPair(fixed: 0xFAF7FF),
        textSecondary: DSColorPair(fixed: 0xD2CCE6),
        textTertiary: DSColorPair(fixed: 0x958EB0),
        separator: DSColorPair(fixed: 0x3C3A62),
        success: DSColorPair(fixed: 0xF0524A),
        shadow: DSColorPair(fixed: 0x000000, alpha: 0.5)
    )

    /// ゼリー（夜のガラスの器。青みのガラス。いつも暗い）
    static let jelly = ThemePalette(
        background: DSColorPair(fixed: 0x161C34),
        surface: DSColorPair(fixed: 0x343E62),
        surfaceSunken: DSColorPair(fixed: 0x232A48),
        segmentSelected: DSColorPair(fixed: 0x454F76),
        surfaceElevated: DSColorPair(fixed: 0x282F50),
        textPrimary: DSColorPair(fixed: 0xF6F8FF),
        textSecondary: DSColorPair(fixed: 0xC8D0E6),
        textTertiary: DSColorPair(fixed: 0x8C95B4),
        separator: DSColorPair(fixed: 0x343E62),
        success: DSColorPair(fixed: 0x9B5DE5),
        shadow: DSColorPair(fixed: 0x000000, alpha: 0.5)
    )

    /// 紙飛行機（夜明け前の空。空色のガラス。いつも暗い）
    static let paperPlane = ThemePalette(
        background: DSColorPair(fixed: 0x121D36),
        surface: DSColorPair(fixed: 0x2E3F64),
        surfaceSunken: DSColorPair(fixed: 0x1D2A48),
        segmentSelected: DSColorPair(fixed: 0x3E5078),
        surfaceElevated: DSColorPair(fixed: 0x22304F),
        textPrimary: DSColorPair(fixed: 0xF5F8FF),
        textSecondary: DSColorPair(fixed: 0xC6D2EA),
        textTertiary: DSColorPair(fixed: 0x8796B8),
        separator: DSColorPair(fixed: 0x2E3F64),
        success: DSColorPair(fixed: 0x5B8DEF),
        shadow: DSColorPair(fixed: 0x000000, alpha: 0.5)
    )

    /// ししおどし（月夜の庭。苔色のガラス。いつも暗い）
    static let shishiOdoshi = ThemePalette(
        background: DSColorPair(fixed: 0x0F1C1A),
        surface: DSColorPair(fixed: 0x2C4440),
        surfaceSunken: DSColorPair(fixed: 0x1B2D2A),
        segmentSelected: DSColorPair(fixed: 0x3A5651),
        surfaceElevated: DSColorPair(fixed: 0x20332F),
        textPrimary: DSColorPair(fixed: 0xF2F7F0),
        textSecondary: DSColorPair(fixed: 0xC4D4C6),
        textTertiary: DSColorPair(fixed: 0x879C8C),
        separator: DSColorPair(fixed: 0x2C4440),
        success: DSColorPair(fixed: 0x6FA35A),
        shadow: DSColorPair(fixed: 0x000000, alpha: 0.55)
    )

    /// ちょうちょ（夕暮れの野原。すみれ色のガラス。いつも暗い）
    static let butterfly = ThemePalette(
        background: DSColorPair(fixed: 0x1A1F33),
        surface: DSColorPair(fixed: 0x3A3C5E),
        surfaceSunken: DSColorPair(fixed: 0x262A44),
        segmentSelected: DSColorPair(fixed: 0x4A4D72),
        surfaceElevated: DSColorPair(fixed: 0x2B2E4C),
        textPrimary: DSColorPair(fixed: 0xFAF8FF),
        textSecondary: DSColorPair(fixed: 0xD3CFE6),
        textTertiary: DSColorPair(fixed: 0x958FB0),
        separator: DSColorPair(fixed: 0x3A3C5E),
        success: DSColorPair(fixed: 0x9B87E0),
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
