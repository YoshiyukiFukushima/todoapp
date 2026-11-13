//
//  DesignSystem.swift
//  todoapp
//
//  方向性 B「みかんの元気」のデザイントークン。
//  View からは数値や16進カラーを直接書かず、必ず `DS` を経由する（docs/design.md）。
//

import SwiftUI
import UIKit

enum DS {}

// MARK: - Color helpers

extension Color {
    /// ライト／ダークで切り替わる色を 0xRRGGBB で作る。
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Accent palette（テーマ・グループ共通の8色）

extension DS {
    /// アプリ全体の差し色、およびグループ色として選べる8色。
    /// - fill: ボタン・チェック・輪など塗り。白いアイコン／太字とのコントラスト 3:1 以上。
    /// - text: 文字として使う差し色。背景に対して 4.5:1 以上。
    /// - soft: 淡い面（チップ・操作タイル・選択中の行）。
    enum Accent: String, CaseIterable, Identifiable, Sendable {
        case mikan, tomato, berry, grape, sky, teal, leaf, cocoa

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .mikan: "みかん"
            case .tomato: "トマト"
            case .berry: "ベリー"
            case .grape: "ぶどう"
            case .sky: "そら"
            case .teal: "みなも"
            case .leaf: "わかば"
            case .cocoa: "ココア"
            }
        }

        var fill: Color {
            switch self {
            case .mikan: Color(light: 0xE86A00, dark: 0xE0720F)
            case .tomato: Color(light: 0xD9483B, dark: 0xE0574A)
            case .berry: Color(light: 0xC2417A, dark: 0xCF4E87)
            case .grape: Color(light: 0x7A5AC8, dark: 0x8A6BD6)
            case .sky: Color(light: 0x2F7FD0, dark: 0x3A8BDB)
            case .teal: Color(light: 0x13897A, dark: 0x179A89)
            case .leaf: Color(light: 0x3E8E3A, dark: 0x4A9E45)
            case .cocoa: Color(light: 0x8A5A3B, dark: 0x9A6A4A)
            }
        }

        var text: Color {
            switch self {
            case .mikan: Color(light: 0xB45309, dark: 0xFFA45C)
            case .tomato: Color(light: 0xB3362B, dark: 0xFF8A7E)
            case .berry: Color(light: 0xA3335F, dark: 0xF28DB8)
            case .grape: Color(light: 0x6446B0, dark: 0xB9A3F2)
            case .sky: Color(light: 0x1F65AD, dark: 0x8EC1F5)
            case .teal: Color(light: 0x0E6E62, dark: 0x6FD3C3)
            case .leaf: Color(light: 0x2F7A2C, dark: 0x8FD38A)
            case .cocoa: Color(light: 0x7A4C30, dark: 0xD7AE91)
            }
        }

        var soft: Color {
            switch self {
            case .mikan: Color(light: 0xFDE6CF, dark: 0x3D2A18)
            case .tomato: Color(light: 0xFBDDD9, dark: 0x3E1F1C)
            case .berry: Color(light: 0xF8DCE8, dark: 0x3A1E2A)
            case .grape: Color(light: 0xE7E0F7, dark: 0x2A2340)
            case .sky: Color(light: 0xDAE9F8, dark: 0x1B2B3D)
            case .teal: Color(light: 0xD4EEEA, dark: 0x15302C)
            case .leaf: Color(light: 0xDDEFD9, dark: 0x1C301B)
            case .cocoa: Color(light: 0xEFE2D8, dark: 0x33261D)
            }
        }

        /// 塗りの上に載せる文字・アイコン色
        var onFill: Color { .white }
    }
}

private struct DSAccentKey: EnvironmentKey {
    static let defaultValue: DS.Accent = .mikan
}

extension EnvironmentValues {
    /// 現在の差し色。テーマ設定から注入する（未設定ならみかん色）。
    var dsAccent: DS.Accent {
        get { self[DSAccentKey.self] }
        set { self[DSAccentKey.self] = newValue }
    }
}

// MARK: - Neutral & semantic colors

extension DS {
    enum Colors {
        /// 画面の一番下の面（あたたかいオフホワイト）
        static let background = Color(light: 0xFFF7EF, dark: 0x17120D)
        /// カード・行の面
        static let surface = Color(light: 0xFFFFFF, dark: 0x241D17)
        /// へこんだ面（セグメントの溝、サイドバー、輪の未達部分）
        static let surfaceSunken = Color(light: 0xF6E7D8, dark: 0x2E251D)
        /// セグメントで選ばれている部分（ダークでは溝より明るくする）
        static let segmentSelected = Color(light: 0xFFFFFF, dark: 0x4A3D31)
        /// シート・浮いたパネル
        static let surfaceElevated = Color(light: 0xFFFFFF, dark: 0x2C241C)

        static let textPrimary = Color(light: 0x3A2410, dark: 0xF7EDE4)
        static let textSecondary = Color(light: 0x8A6A4F, dark: 0xBFA892)
        /// 補助的な飾り（区切りの記号、無効状態）。本文には使わない。
        static let textTertiary = Color(light: 0xB59A82, dark: 0x8C7663)

        static let separator = Color(light: 0xF0E2D4, dark: 0x3A3027)

        /// 期限切れ・削除
        static let danger = Color(light: 0xD23B2E, dark: 0xFF6B5E)
        static let dangerSoft = Color(light: 0xFBE0DD, dark: 0x3E1E1B)
        /// 赤い塗り（バッジなど）の上に載せる文字
        static let onDanger = Color.white
        /// 進み具合 100% の輪
        static let success = Color(light: 0x3FA34D, dark: 0x5CC46A)

        /// サイドバーを開いたときに一覧へかける暗幕
        static let scrim = Color(uiColor: UIColor { traits in
            UIColor.black.withAlphaComponent(traits.userInterfaceStyle == .dark ? 0.5 : 0.25)
        })

        /// 影の色（ダークでは黒を濃くする）
        static let shadow = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.black.withAlphaComponent(0.45)
                : UIColor(red: 0.36, green: 0.20, blue: 0.06, alpha: 0.10)
        })
    }
}

// MARK: - Typography（SF Pro Rounded＋ヒラギノ角ゴ、Dynamic Type 準拠）

extension DS {
    enum Typography {
        /// 画面の大見出し（グループ名など）
        static let screenTitle = Font.system(.title2, design: .rounded, weight: .heavy)
        /// セクション見出し（未完了・サブグループ・完了済み）
        static let sectionTitle = Font.system(.headline, design: .rounded, weight: .bold)
        /// タスク追加・詳細のタイトル入力
        static let inputTitle = Font.system(.title3, design: .rounded, weight: .semibold)
        /// タスク名
        static let taskTitle = Font.system(.body, design: .rounded, weight: .semibold)
        /// 本文（メモなど）
        static let body = Font.system(.body, design: .rounded, weight: .regular)
        /// 補足（期限・繰り返し）
        static let meta = Font.system(.subheadline, design: .rounded, weight: .medium)
        /// 小さな補足
        static let caption = Font.system(.footnote, design: .rounded, weight: .medium)
        /// 件数バッジ・タブの数字
        static let counter = Font.system(.caption, design: .rounded, weight: .bold).monospacedDigit()
        /// ボタンの文字
        static let button = Font.system(.headline, design: .rounded, weight: .bold)
        /// 輪の中の数字など大きな数
        static let number = Font.system(.title3, design: .rounded, weight: .heavy).monospacedDigit()
        /// タブの文字（選択中／それ以外）
        static let tabSelected = Font.system(.subheadline, design: .rounded, weight: .bold)
        static let tab = Font.system(.subheadline, design: .rounded, weight: .medium)
        /// 行やボタンの中のアイコン
        static let icon = Font.system(.title3, design: .rounded, weight: .semibold)
        /// ＋ボタンなど大きなアイコン
        static let iconLarge = Font.system(.title2, design: .rounded, weight: .bold)
        /// 開閉の矢印など小さなアイコン
        static let iconSmall = Font.system(.caption, design: .rounded, weight: .bold)
    }
}

// MARK: - Opacity / Stroke / Layout

extension DS {
    enum Opacity {
        /// 選択されていないグループの色
        static let unselected: Double = 0.3
        /// 使えない状態のボタン
        static let disabled: Double = 0.4
        /// 完了したタスクの行
        static let completed: Double = 0.6
        /// 完了したタスクのメモ
        static let completedMemo: Double = 0.5
        /// 「サブグループを追加」などの点線の枠
        static let dashedBorder: Double = 0.6
    }

    enum Stroke {
        /// 行の枠線
        static let hairline: CGFloat = 0.5
        /// 選択中の枠線
        static let regular: CGFloat = 2
        /// チェックの丸の線
        static let check: CGFloat = 2.5
        /// 点線の間隔
        static let dash: [CGFloat] = [5, 4]
    }

    enum Layout {
        /// グループアイコン右上の件数バッジのずれ
        static let badgeOffset = CGSize(width: 6, height: -4)
        /// 長押しで出る名前の吹き出しの位置
        static let tooltipOffsetY: CGFloat = -28
        /// グループ管理パネルの幅（画面幅に対する割合）
        static let sidePanelWidthRatio: CGFloat = 0.8
        /// メモの 1 行表示で切り詰める文字数
        static let memoPreviewLength = 50
        /// タスク追加・詳細シートのメモ欄の最小の高さ
        static let memoEditorMinHeight: CGFloat = 100
    }
}

// MARK: - Spacing / Radius / Size

extension DS {
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32

        /// 画面左右の余白
        static let screenMargin: CGFloat = l
        /// 行と行の間
        static let rowGap: CGFloat = s
    }

    enum Radius {
        /// 小さな部品（四角いチェック、タグ）
        static let s: CGFloat = 8
        /// セグメントの中・チップ
        static let m: CGFloat = 12
        /// タスクカード・操作タイル
        static let l: CGFloat = 18
        /// シート・大きなカード
        static let xl: CGFloat = 26
        // ボタン・チップは Capsule() を使う
    }

    enum Size {
        /// HIG の最小タップ領域
        static let minTapTarget: CGFloat = 44
        /// チェックの丸
        static let checkbox: CGFloat = 26
        /// サイドバーのグループアイコン
        static let groupIcon: CGFloat = 44
        /// サイドバー（閉じたとき・開いたとき）
        static let sidebarCollapsed: CGFloat = 68
        static let sidebarExpanded: CGFloat = 248
        /// 浮いた＋ボタン（メイン画面のタスク追加の唯一の入口）
        static let fab: CGFloat = 60
        /// ＋ボタンに最後の行が隠れないよう、一覧の下に足す余白
        static let fabClearance: CGFloat = fab + Spacing.xl * 2
        /// 進み具合の輪
        static let ring: CGFloat = 44
        static let ringLineWidth: CGFloat = 5
        /// タブ（セグメント）1 つ分の高さ。溝の余白と合わせて 44pt 以上になる
        static let segmentHeight: CGFloat = 36
    }
}

// MARK: - Shadow

extension DS {
    enum Elevation {
        /// 影なし（完了したタスクなど）
        case none
        /// 行・カード（ほぼ平ら）
        case card
        /// 浮いた＋ボタン・サイドバーを開いたとき
        case floating

        var radius: CGFloat {
            switch self {
            case .none: 0
            case .card: 6
            case .floating: 16
            }
        }

        var y: CGFloat {
            switch self {
            case .none: 0
            case .card: 2
            case .floating: 6
            }
        }
    }
}

extension View {
    func dsShadow(_ elevation: DS.Elevation) -> some View {
        shadow(color: elevation == .none ? .clear : DS.Colors.shadow, radius: elevation.radius, x: 0, y: elevation.y)
    }
}

// MARK: - Motion

extension DS {
    enum Motion {
        /// 開閉・選択など、操作への標準の反応
        static let standard = Animation.spring(response: 0.35, dampingFraction: 0.82)
        /// チェックなど小さく弾む反応
        static let bouncy = Animation.spring(response: 0.3, dampingFraction: 0.6)

        /// 完了したタスクのフェードアウト
        static let fade = Animation.easeInOut(duration: 0.3)

        /// 「視差効果を減らす」がオンなら nil（＝アニメーションなし）を返す
        static func respecting(_ reduceMotion: Bool, _ animation: Animation = standard) -> Animation? {
            reduceMotion ? nil : animation
        }
    }
}

// MARK: - Catalog（確認用。DEBUG ビルドで起動引数 -ds-catalog を付けると表示）

#if DEBUG
struct DesignSystemCatalog: View {
    @State private var accent: DS.Accent = .mikan

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                Text("デザインシステム")
                    .font(DS.Typography.screenTitle)
                    .foregroundStyle(DS.Colors.textPrimary)

                section("差し色（テーマ・グループ）") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.s), count: 4),
                              spacing: DS.Spacing.s) {
                        ForEach(DS.Accent.allCases) { item in
                            Button { accent = item } label: {
                                VStack(spacing: DS.Spacing.xs) {
                                    Circle()
                                        .fill(item.fill)
                                        .frame(width: DS.Size.groupIcon, height: DS.Size.groupIcon)
                                        .overlay {
                                            Image(systemName: item == accent ? "checkmark" : "house.fill")
                                                .font(DS.Typography.sectionTitle)
                                                .foregroundStyle(item.onFill)
                                        }
                                    Text(item.displayName)
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(item.text)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DS.Spacing.s)
                                .background(item.soft, in: RoundedRectangle(cornerRadius: DS.Radius.m))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                section("文字") {
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("ホーム 12 / 見出し").font(DS.Typography.screenTitle)
                        Text("未完了 4 / セクション").font(DS.Typography.sectionTitle)
                        Text("牛乳と卵を買う / タスク名").font(DS.Typography.taskTitle)
                        Text("低脂肪乳、Lサイズの卵10個 / 本文").font(DS.Typography.body)
                        Text("今日・毎日 / 補足").font(DS.Typography.meta)
                            .foregroundStyle(DS.Colors.textSecondary)
                        Text("2日遅れ / 期限切れ").font(DS.Typography.meta)
                            .foregroundStyle(DS.Colors.danger)
                    }
                    .foregroundStyle(DS.Colors.textPrimary)
                }

                section("部品") {
                    VStack(spacing: DS.Spacing.rowGap) {
                        sampleRow("牛乳と卵を買う", meta: "今日", metaColor: DS.Colors.textSecondary, symbol: nil)
                        sampleRow("洗濯物を取り込む", meta: "今日", metaColor: DS.Colors.textSecondary, symbol: "repeat")
                        sampleRow("粗大ごみの収集を申し込む", meta: "2日遅れ", metaColor: DS.Colors.danger, symbol: nil)

                        HStack(spacing: DS.Spacing.m) {
                            ZStack {
                                Circle().stroke(DS.Colors.surfaceSunken, lineWidth: DS.Size.ringLineWidth)
                                Circle().trim(from: 0, to: 0.25)
                                    .stroke(accent.fill, style: StrokeStyle(lineWidth: DS.Size.ringLineWidth, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                Text("1/4").font(DS.Typography.counter).foregroundStyle(DS.Colors.textPrimary)
                            }
                            .frame(width: DS.Size.ring, height: DS.Size.ring)

                            // カプセル型の塗りボタンの見本。使う場所は画面ごとにフェーズ4で決める（docs/design.md）
                            Text("主なボタン（見本）")
                                .font(DS.Typography.button)
                                .foregroundStyle(accent.onFill)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(accent.fill, in: Capsule())
                        }
                    }
                }
            }
            .padding(DS.Spacing.screenMargin)
            .padding(.bottom, DS.Size.fabClearance)
        }
        .background(DS.Colors.background)
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "plus")
                .font(DS.Typography.iconLarge)
                .foregroundStyle(accent.onFill)
                .frame(width: DS.Size.fab, height: DS.Size.fab)
                .background(accent.fill, in: Circle())
                .dsShadow(.floating)
                .padding(DS.Spacing.xl)
        }
        .environment(\.dsAccent, accent)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text(title)
                .font(DS.Typography.sectionTitle)
                .foregroundStyle(DS.Colors.textSecondary)
            content()
        }
    }

    private func sampleRow(_ title: String, meta: String, metaColor: Color, symbol: String?) -> some View {
        HStack(spacing: DS.Spacing.m) {
            Circle()
                .strokeBorder(accent.fill, lineWidth: 2.5)
                .frame(width: DS.Size.checkbox, height: DS.Size.checkbox)
                .frame(width: DS.Size.minTapTarget, height: DS.Size.minTapTarget)
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text(title).font(DS.Typography.taskTitle).foregroundStyle(DS.Colors.textPrimary)
                HStack(spacing: DS.Spacing.xs) {
                    Text(meta)
                    if let symbol { Image(systemName: symbol) }
                }
                .font(DS.Typography.meta)
                .foregroundStyle(metaColor)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, DS.Spacing.xs)
        .padding(.trailing, DS.Spacing.l)
        .background(DS.Colors.surface, in: RoundedRectangle(cornerRadius: DS.Radius.l))
        .dsShadow(.card)
    }
}

#Preview("Light") { DesignSystemCatalog() }
#Preview("Dark") { DesignSystemCatalog().preferredColorScheme(.dark) }
#endif
