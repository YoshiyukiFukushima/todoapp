//
//  BubbleTokens.swift
//  todoapp
//
//  泡のテーマだけで使う色と動きの値。
//

import SwiftUI

extension DS {
    enum Bubble {
        // MARK: 水の中の背景
        /// 背景のグラデーション（上・下）
        static let deepTop = Color(fixed: 0x162052)
        static let deepBottom = Color(fixed: 0x0A0F2C)
        /// 背景でぼんやり光る色（青・紫・緑）
        static let glowBlue = Color(fixed: 0x1C7CFF)
        static let glowViolet = Color(fixed: 0x7C6BFF)
        static let glowGreen = Color(fixed: 0x12B886)

        // MARK: ガラスのカード
        static let glassTop = Color(fixed: 0x4E5DB4).opacity(0.55)
        static let glassBottom = Color(fixed: 0x28346F).opacity(0.55)
        static let rim = Color.white

        // MARK: シャボン玉
        /// 泡のふちの青み
        static let tint = Color(fixed: 0x8FB8FF)
        /// 空の泡（未完了のチェック）の奥の色
        static let sphereEdge = Color(fixed: 0x2C3C92)
        /// 満ちた泡（完了したチェック・＋ボタン）
        static let filledLight = Color(fixed: 0xB9DDFF)
        static let filledMid = Color(fixed: 0x3E8CF0)
        static let filledDeep = Color(fixed: 0x1D44A8)

        // MARK: 動き
        /// チェックした泡がふくらんでから縮み、はじけるまで
        static let popDelay: TimeInterval = 0.26
        /// 全部終わったときに、カードから泡があふれ出す間隔
        static let celebrationStagger: TimeInterval = 0.12
    }
}
