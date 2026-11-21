//
//  WaterTokens.swift
//  todoapp
//
//  水滴のテーマだけで使う色と動きの値。
//  水は透明なので、色で塗らず「ふちの光・映り込み・揺れ」で形を見せる。
//

import SwiftUI

extension DS {
    enum Water {
        // MARK: 深い水の背景
        static let deepTop = Color(fixed: 0x10284F)
        static let deepBottom = Color(fixed: 0x060F22)
        /// 背景でぼんやり光る色（青・水色・藍）
        static let glows: [Color] = [Color(fixed: 0x2F86FF), Color(fixed: 0x3FB4E8), Color(fixed: 0x3550C8)]

        // MARK: ガラスのカード・未完了の玉・＋ボタン
        static let glass = GlassTint(
            glassTop: Color(fixed: 0x5E8BD0).opacity(0.45), glassBottom: Color(fixed: 0x22406F).opacity(0.5),
            sphereTint: Color(fixed: 0xA9CFFF), sphereEdge: Color(fixed: 0x1F4682),
            filledLight: Color(fixed: 0xCDE6FF), filledMid: Color(fixed: 0x4C95EE), filledDeep: Color(fixed: 0x1D52B0)
        )

        // MARK: 水（しずく・水玉・たまった水）
        /// ふちと映り込みの光
        static let rim = Color.white
        /// 水のほんのりした青（ごく薄く使う）
        static let tint = Color(fixed: 0x8EC4FF)
        static let deep = Color(fixed: 0x3D7FE0)
        /// カードにたまった水（上：水面近く／下：底）
        static let poolTop = Color(fixed: 0x8FC0F5).opacity(0.28)
        static let poolBottom = Color(fixed: 0x4F86D6).opacity(0.42)

        // MARK: 動き
        /// しずくが落ちてきて、ボタンに当たるまで
        static let fallDuration: TimeInterval = 0.3
        /// しずくが落ち始める高さ（ボタンの上、pt）
        static let fallHeight: CGFloat = 90
        /// 水がたまるまで（当たってから）
        static let fillDuration: TimeInterval = 0.7
        /// 水が引くまで（チェックを外したとき）
        static let drainDuration: TimeInterval = 0.4
        /// カードにたまる水の高さ（カードの高さに対する割合）
        static let poolLevel: CGFloat = 0.5
        /// 波紋が広がる時間
        static let rippleDuration: TimeInterval = 0.7
        /// 全部終わったときの雨が降り続く時間
        static let rainSpread: TimeInterval = 1.6
    }
}
