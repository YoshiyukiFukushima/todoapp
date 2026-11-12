//
//  DSModifiers.swift
//  todoapp
//
//  画面をまたいで使う見た目・振る舞いの共通部品。
//

import SwiftUI

extension View {
    /// 削除前の確認ダイアログ（タスク一覧・タスク詳細・グループ管理で共通）
    func confirmDelete(isPresented: Binding<Bool>, onDelete: @escaping () -> Void) -> some View {
        confirmationDialog("本当に削除しますか？", isPresented: isPresented, titleVisibility: .visible) {
            Button("削除", role: .destructive, action: onDelete)
            Button("キャンセル", role: .cancel) {}
        }
    }

    /// Form を DS の背景色にする（行の色は `dsFormRow()` で揃える）
    func dsFormBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(DS.Colors.background)
    }

    /// Form の Section／行の背景を DS のカード色にする
    func dsFormRow() -> some View {
        listRowBackground(DS.Colors.surface)
    }

    /// アプリ全体に差し色・丸い書体を行き渡らせる。ルートとシートの中身に付ける。
    func dsRoot(accent: DS.Accent) -> some View {
        environment(\.dsAccent, accent)
            .tint(accent.fill)
            .fontDesign(.rounded)
            .foregroundStyle(DS.Colors.textPrimary)
    }
}

/// 見出しつきの Form セクション。見出しを補足色、行をカード色にする。
/// （ルートの foregroundStyle がシステムの見出し色を上書きしてしまうため、見出しの色を明示する）
struct DSFormSection<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        Section {
            content
        } header: {
            Text(title)
                .foregroundStyle(DS.Colors.textSecondary)
        }
        .dsFormRow()
    }
}

extension AppTheme {
    /// 【暫定・フェーズ3】今のテーマ設定を新しい差し色へ対応づける。
    /// テーマの保存値の移し替えと既定値（みかん）はフェーズ4で決める（docs/design.md）。
    var accent: DS.Accent {
        switch self {
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
}
