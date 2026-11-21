//
//  Theme.swift
//  todoapp
//
//  テーマの仕組み。docs/design.md「テーマの増やし方」参照。
//
//  テーマは 3 つの部品でできている：
//  - ThemePalette（ThemePalettes.swift）: 背景・カード・文字などの色の表
//  - DS.Accent: 差し色
//  - ThemeStyle（ThemeStyle.swift）: 背景・カード・チェック・完了演出の「描き方」
//
//  色だけ違うテーマは、ColorTheme に case を足して palette と accent を返すだけで作れる。
//  見た目の形まで変えるテーマは、ThemeStyle に case を足し、Themes/<名前>/ に部品を置く。
//

import SwiftUI
import UIKit

/// 設定で選ぶテーマ（保存するのは rawValue）
nonisolated enum ColorTheme: String, CaseIterable, Identifiable, Sendable {
    case mikan, tomato, berry, grape, sky, teal, leaf, cocoa, mono
    /// 泡（シャボン玉）。いつも暗い水の中の見た目
    case bubble
    /// 桜。夜桜の庭で、チェックすると 5 枚の花びらが咲く。いつも暗い
    case sakura
    /// マーガレット。夜の草原で、チェックすると白い花が咲く。いつも暗い
    case margaret
    /// 氷の結晶（六花）。雪の夜で、チェックすると結晶が回りながら広がる。いつも暗い
    case rikka
    /// 水滴。深い水の中で、しずくが落ちて水玉になり、カードに水がたまる。いつも暗い
    case water
    /// 判子。和紙のカードに、朱色の「済」を押す。いつも明るい
    case stamp
    /// ろうそく。まだのタスクは火に照らされ、終えると火が消える。いつも暗い
    case candle
    /// 星座。終えると星が灯り、全部終えると星座になる。いつも暗い
    case constellation

    var id: String { rawValue }

    static let defaultTheme: ColorTheme = .mikan

    /// 色の表。UIColor の動的な色の中から読むので nonisolated にしている
    var palette: ThemePalette {
        switch self {
        case .mono: .mono
        case .bubble: .bubble
        case .sakura: .sakura
        case .margaret: .margaret
        case .rikka: .rikka
        case .water: .water
        case .stamp: .stamp
        case .candle: .candle
        case .constellation: .constellation
        default: .warm
        }
    }

    /// 背景・カード・チェックなどの描き方
    var style: ThemeStyle {
        switch self {
        case .bubble: .bubble
        case .sakura: .flower(.sakura)
        case .margaret: .flower(.margaret)
        case .rikka: .flower(.rikka)
        case .water: .water
        case .stamp: .stamp
        case .candle: .candle
        case .constellation: .constellation
        default: .standard
        }
    }

    /// ライト／ダークを固定するテーマ（nil なら端末の設定に従う）
    var fixedInterfaceStyle: UIUserInterfaceStyle? {
        switch style {
        case .standard: nil
        case .bubble, .flower, .water, .candle, .constellation: .dark
        case .stamp: .light
        }
    }

    /// グループの色も墨色（グレー）にするか
    var isMonochrome: Bool { self == .mono }
}

extension ColorTheme {
    var displayName: String {
        switch self {
        case .mono: "モノクロ"
        case .bubble: "泡"
        case .sakura: "桜"
        case .margaret: "マーガレット"
        case .rikka: "結晶"
        case .water: "水滴"
        case .stamp: "判子"
        case .candle: "ろうそく"
        case .constellation: "星座"
        default: accent.displayName
        }
    }

    /// 差し色
    var accent: DS.Accent {
        switch self {
        case .mikan: .mikan
        case .tomato: .tomato
        case .berry: .berry
        case .grape: .grape
        case .sky: .sky
        case .teal: .teal
        case .leaf: .leaf
        case .cocoa: .cocoa
        case .mono: .ink
        case .bubble: .sky
        case .sakura: .berry
        case .margaret: .leaf
        case .rikka: .sky
        case .water: .sky
        case .stamp: .tomato
        case .candle: .mikan
        case .constellation: .grape
        }
    }
}

// MARK: - テーマを UIKit のトレイト経由で色まで届ける

/// UIKit 側のトレイト。DS.Colors の動的な UIColor がこれを見て、テーマの色の表から値を返す。
struct DSThemeTrait: UITraitDefinition {
    static let defaultValue = ColorTheme.defaultTheme
    static let affectsColorAppearance = true
    static let name = "DSTheme"
}

extension UITraitCollection {
    var dsTheme: ColorTheme { self[DSThemeTrait.self] }
}

extension UIMutableTraits {
    var dsTheme: ColorTheme {
        get { self[DSThemeTrait.self] }
        set { self[DSThemeTrait.self] = newValue }
    }
}

/// SwiftUI 側の環境値。UIKit のトレイトとつながっている。
struct DSThemeKey: EnvironmentKey {
    static let defaultValue = ColorTheme.defaultTheme
}

extension DSThemeKey: UITraitBridgedEnvironmentKey {
    static func read(from traitCollection: UITraitCollection) -> ColorTheme {
        traitCollection.dsTheme
    }

    static func write(to mutableTraits: inout UIMutableTraits, value: ColorTheme) {
        mutableTraits.dsTheme = value
    }
}

extension EnvironmentValues {
    /// 今のテーマ
    var dsTheme: ColorTheme {
        get { self[DSThemeKey.self] }
        set { self[DSThemeKey.self] = newValue }
    }

    /// 今のテーマの描き方
    var dsStyle: ThemeStyle { dsTheme.style }

    /// モノクロのテーマかどうか（グループの色をグレーにする）
    var dsMonochrome: Bool { dsTheme.isMonochrome }
}
