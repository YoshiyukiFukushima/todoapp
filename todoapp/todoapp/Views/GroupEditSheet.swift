//
//  GroupEditSheet.swift
//  todoapp
//
//  グループの作成・編集。上に大きなプレビュー、下に色とアイコンの選択。
//

import SwiftUI

struct GroupEditSheet: View {
    let group: TodoGroup?
    let groupViewModel: GroupViewModel
    var nextOrder: Int = 0

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dsAccent) private var themeAccent
    @Environment(\.dsMonochrome) private var isMonochrome
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var name: String = ""
    @State private var icon: String = GroupAppearance.letterIcon
    @State private var color: DS.Accent = .mikan
    @FocusState private var nameFocused: Bool

    /// 名前が空のときの 1 文字目の見本
    private static let placeholderLetter = "あ"

    private var isNew: Bool { group == nil }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// プレビューで表示するアイコン
    private var previewGlyph: GroupGlyph {
        GroupAppearance.glyph(icon: icon, name: name.isEmpty ? Self.placeholderLetter : name)
    }

    /// モノクロのときはグループもグレーで表示する（docs/design.md）
    private var displayAccent: DS.Accent { isMonochrome ? .ink : color }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                    preview
                    colorSection
                    iconSection
                }
                .padding(DS.Spacing.screenMargin)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(DS.Colors.background)
            .navigationTitle(isNew ? "グループを追加" : "グループの編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: save) {
                        Text("保存").foregroundStyle(themeAccent.onFill)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(themeAccent.fill)
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : DS.Opacity.disabled)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationBackground { DS.Colors.background }
        .onAppear(perform: loadInitialValues)
    }

    // MARK: - プレビュー（アイコン＋名前）

    private var preview: some View {
        VStack(spacing: DS.Spacing.l) {
            ZStack {
                Circle().fill(displayAccent.fill)
                glyphView(previewGlyph, font: DS.Typography.previewGlyph)
                    .foregroundStyle(displayAccent.onFill)
            }
            .frame(width: DS.Size.groupPreview, height: DS.Size.groupPreview)
            .animation(DS.Motion.respecting(reduceMotion), value: color)
            .accessibilityHidden(true)

            TextField("グループ名", text: $name)
                .font(DS.Typography.inputTitle)
                .multilineTextAlignment(.center)
                .focused($nameFocused)
                .submitLabel(.done)
                .padding(DS.Spacing.l)
                .background(DS.Colors.surface, in: RoundedRectangle(cornerRadius: DS.Radius.l))
                .accessibilityLabel("グループ名")
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 色

    private var colorSection: some View {
        SheetCard("色") {
            HStack(spacing: 0) {
                ForEach(DS.Accent.palette) { accent in
                    let isSelected = color == accent
                    Button {
                        withAnimation(DS.Motion.respecting(reduceMotion)) { color = accent }
                    } label: {
                        Circle()
                            .fill(accent.fill)
                            .frame(width: DS.Size.colorSwatch, height: DS.Size.colorSwatch)
                            .overlay {
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(DS.Typography.iconSmall)
                                        .foregroundStyle(accent.onFill)
                                }
                            }
                            .padding(DS.Spacing.xxs)
                            .overlay {
                                Circle().strokeBorder(isSelected ? DS.Colors.textPrimary : .clear,
                                                      lineWidth: DS.Stroke.regular)
                            }
                            .frame(maxWidth: .infinity, minHeight: DS.Size.minTapTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(accent.displayName)
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
            if isMonochrome {
                Text("モノクロのテーマでは、グループの色はグレーで表示されます。")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.textSecondary)
            }
        }
    }

    // MARK: - アイコン

    private var iconSection: some View {
        SheetCard("アイコン") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.s), count: 5),
                      spacing: DS.Spacing.s) {
                iconCell(GroupAppearance.letterIcon,
                         glyph: .letter(name.trimmingCharacters(in: .whitespaces).first.map(String.init) ?? Self.placeholderLetter),
                         label: "名前の1文字目")
                ForEach(GroupAppearance.iconChoices, id: \.self) { symbol in
                    iconCell(symbol, glyph: .symbol(symbol), label: GroupAppearance.iconNames[symbol] ?? symbol)
                }
            }
        }
    }

    private func iconCell(_ value: String, glyph: GroupGlyph, label: String) -> some View {
        let isSelected = icon == value
        return Button {
            icon = value
        } label: {
            glyphView(glyph, font: DS.Typography.icon)
                .foregroundStyle(isSelected ? displayAccent.onFill : displayAccent.text)
                .frame(maxWidth: .infinity, minHeight: DS.Size.groupIcon + DS.Spacing.s)
                .background(isSelected ? displayAccent.fill : DS.Colors.surface,
                            in: RoundedRectangle(cornerRadius: DS.Radius.m))
                .contentShape(RoundedRectangle(cornerRadius: DS.Radius.m))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    @ViewBuilder
    private func glyphView(_ glyph: GroupGlyph, font: Font) -> some View {
        switch glyph {
        case .symbol(let name):
            Image(systemName: name).font(font)
        case .letter(let letter):
            Text(letter).font(font.weight(.heavy))
        }
    }

    // MARK: - 読み込み・保存

    private func loadInitialValues() {
        if let group {
            name = group.name
            color = group.accent
            if case .symbol(let symbol) = group.glyph {
                icon = symbol
            } else {
                icon = GroupAppearance.letterIcon
            }
        } else {
            color = themeAccent == .ink ? .mikan : themeAccent
            icon = GroupAppearance.letterIcon
            nameFocused = true
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let group {
            groupViewModel.updateGroup(group, name: trimmed, icon: icon, colorHex: color.rawValue)
        } else {
            groupViewModel.addGroup(name: trimmed, icon: icon, colorHex: color.rawValue, order: nextOrder)
        }
        dismiss()
    }
}
