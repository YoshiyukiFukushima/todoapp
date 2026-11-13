//
//  Theme.swift
//  todoapp
//
//  テーマ（差し色 8 色＋モノクロ）と、モノクロを色トークンまで届ける仕組み。
//  docs/design.md「設定・テーマ」参照。
//

import SwiftUI
import UIKit

/// 設定で選ぶテーマ
enum ColorTheme: String, CaseIterable, Identifiable, Sendable {
    case mikan, tomato, berry, grape, sky, teal, leaf, cocoa, mono

    var id: String { rawValue }

    static let defaultTheme: ColorTheme = .mikan

    var displayName: String {
        self == .mono ? "モノクロ" : accent.displayName
    }

    /// 差し色（モノクロは墨色）
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
        }
    }

    var isMonochrome: Bool { self == .mono }
}

// MARK: - モノクロを UIKit のトレイト経由で色まで届ける

/// UIKit 側のトレイト。動的な UIColor がこれを見て白黒の値を返す。
struct DSMonochromeTrait: UITraitDefinition {
    static let defaultValue = false
    static let affectsColorAppearance = true
    static let name = "DSMonochrome"
}

extension UITraitCollection {
    var dsMonochrome: Bool { self[DSMonochromeTrait.self] }
}

extension UIMutableTraits {
    var dsMonochrome: Bool {
        get { self[DSMonochromeTrait.self] }
        set { self[DSMonochromeTrait.self] = newValue }
    }
}

/// SwiftUI 側の環境値。UIKit のトレイトとつながっている。
struct DSMonochromeKey: EnvironmentKey {
    static let defaultValue = false
}

extension DSMonochromeKey: UITraitBridgedEnvironmentKey {
    static func read(from traitCollection: UITraitCollection) -> Bool {
        traitCollection.dsMonochrome
    }

    static func write(to mutableTraits: inout UIMutableTraits, value: Bool) {
        mutableTraits.dsMonochrome = value
    }
}

extension EnvironmentValues {
    /// モノクロのテーマかどうか
    var dsMonochrome: Bool {
        get { self[DSMonochromeKey.self] }
        set { self[DSMonochromeKey.self] = newValue }
    }
}

// MARK: - ウィンドウ全体に反映

extension View {
    /// モノクロかどうかをウィンドウのトレイトに書く。
    /// シートは別の画面として出るため、環境値だけでは中の色まで届かない。ウィンドウに書けばシートも含めて全部に効く。
    func dsApplyMonochromeToWindows(_ isMonochrome: Bool) -> some View {
        onChange(of: isMonochrome, initial: true) { _, newValue in
            for scene in UIApplication.shared.connectedScenes {
                guard let windowScene = scene as? UIWindowScene else { continue }
                for window in windowScene.windows {
                    window.traitOverrides.dsMonochrome = newValue
                }
            }
        }
    }
}
