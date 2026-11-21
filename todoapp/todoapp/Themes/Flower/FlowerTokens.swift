//
//  FlowerTokens.swift
//  todoapp
//
//  花のテーマの色・形・動きの値。花の種類（FlowerKind）ごとに 1 組（FlowerSpec）を持つ。
//  新しい花を足すときは、FlowerKind に case を足し、FlowerSpec を 1 つ作るだけでよい。
//  泡は「ぱちん」と一瞬ではじけるが、花は少しゆっくり咲かせる（速さも花ごとに変える）。
//

import SwiftUI

/// 花の種類
nonisolated enum FlowerKind: Sendable, Equatable {
    /// 桜：花びら 5 枚、先に切れ込み。夜桜の庭
    case sakura
    /// マーガレット：白く細長い花びらがたくさん、大きな黄色い花芯。夜の草原
    case margaret
}

/// 花びらの形
enum PetalStyle {
    /// 付け根が細く、先に小さな切れ込み（桜）
    case notched
    /// 細長く、先が丸い（マーガレット）
    case slender
}

/// 1 種類の花の、色・形・動き
struct FlowerSpec {
    // MARK: 形
    let petalCount: Int
    let petalStyle: PetalStyle
    /// 花びらの長さ・幅（つぼみの直径に対する割合）
    let petalLength: CGFloat
    let petalWidth: CGFloat
    /// 花びらの付け根を、中心からどれだけ離すか（割合）
    let petalInset: CGFloat
    /// 咲いたときの花芯の直径（割合）
    let stamenSize: CGFloat

    // MARK: 咲き方（progress 0〜1 の中での割合）
    /// 1 枚ごとの開き始めのずれ
    let stagger: Double
    /// 1 枚が開くのにかかる割合
    let span: Double
    /// 開きながら花びら自体をひねる角度
    let twist: Double
    /// 開きながら花全体が回り込む角度
    let swirl: Double

    // MARK: 色
    let petalTip: Color
    let petalBase: Color
    let petalVein: Color
    let petalEdge: Color
    /// 舞い落ちる花びらの色（少しずつ違う色）
    let petalShades: [Color]
    let stamenLight: Color
    let stamenMid: Color
    let stamenDeep: Color
    /// 花芯の上のチェック
    let checkmark: Color
    /// カード・つぼみ・＋ボタン
    let glass: GlassTint
    /// 背景のグラデーション（上・下）と、ぼんやり光る 3 色（左上・右・左下）
    let deepTop: Color
    let deepBottom: Color
    let glows: [Color]

    // MARK: 動き
    /// つぼみがきゅっと縮む時間
    let squeeze: TimeInterval
    /// 縮んでから咲き始めるまで
    let bloomDelay: TimeInterval
    /// 花びらが 1 枚ずつ開ききるまで
    let bloomDuration: TimeInterval
    /// チェックを外したとき、花びらが逆の順で閉じる時間
    let closeDuration: TimeInterval
    /// 咲いたあと舞い落ちる花びらの数
    let shedCount: ClosedRange<Int>
    /// 舞い落ちる花びらの大きさ（px）。降ってくるときと背景
    let fallingSize: ClosedRange<Double>

    /// 咲いてから花びらが舞い落ち始めるまで
    var shedDelay: TimeInterval { bloomDelay + bloomDuration * 0.85 }
}

extension FlowerKind {
    var spec: FlowerSpec {
        switch self {
        case .sakura: .sakura
        case .margaret: .margaret
        }
    }
}

extension FlowerSpec {
    static let sakura = FlowerSpec(
        petalCount: 5,
        petalStyle: .notched,
        petalLength: 0.7,
        petalWidth: 0.62,
        petalInset: 0.04,
        stamenSize: 0.6,
        stagger: 0.1,
        span: 0.5,
        twist: -38,
        swirl: -24,
        petalTip: Color(fixed: 0xFDEDF3),
        petalBase: Color(fixed: 0xE9A0BE),
        petalVein: Color(fixed: 0xCF6F98),
        petalEdge: .white,
        petalShades: [Color(fixed: 0xF8C9DA), Color(fixed: 0xF3B3CB), Color(fixed: 0xFBDCE7), Color(fixed: 0xEFA6C3)],
        stamenLight: Color(fixed: 0xFFF2BF),
        stamenMid: Color(fixed: 0xF2C35E),
        stamenDeep: Color(fixed: 0xC98B2B),
        checkmark: Color(fixed: 0x6B4A1E),
        glass: GlassTint(
            glassTop: Color(fixed: 0xA587B8).opacity(0.42), glassBottom: Color(fixed: 0x5B3F69).opacity(0.5),
            sphereTint: Color(fixed: 0xF6CADD), sphereEdge: Color(fixed: 0x6E4A7C),
            filledLight: Color(fixed: 0xFFDDEB), filledMid: Color(fixed: 0xEE8DB6), filledDeep: Color(fixed: 0xB24E7F)
        ),
        deepTop: Color(fixed: 0x2B1B37),
        deepBottom: Color(fixed: 0x140C1A),
        glows: [Color(fixed: 0x7B5CF0), Color(fixed: 0xC9558C), Color(fixed: 0x5E9A2E)],
        squeeze: 0.16,
        bloomDelay: 0.2,
        bloomDuration: 1.0,
        closeDuration: 0.55,
        shedCount: 3...4,
        fallingSize: 10...18
    )

    /// マーガレットは花びらが多いので、1 枚ずつのずれを小さくして、くるっと回りながら広がる
    static let margaret = FlowerSpec(
        petalCount: 16,
        petalStyle: .slender,
        petalLength: 0.66,
        petalWidth: 0.2,
        petalInset: 0.06,
        stamenSize: 0.56,
        stagger: 0.034,
        span: 0.42,
        twist: 0,
        swirl: -70,
        petalTip: Color(fixed: 0xFFFFFF),
        petalBase: Color(fixed: 0xE6EEDB),
        petalVein: Color(fixed: 0xBFCCB2),
        petalEdge: Color(fixed: 0xD7E2CC),
        petalShades: [Color(fixed: 0xF4F7EE), Color(fixed: 0xE9F0E0), Color(fixed: 0xFFFFFF), Color(fixed: 0xF7F3DF)],
        stamenLight: Color(fixed: 0xFFF4A8),
        stamenMid: Color(fixed: 0xF7C531),
        stamenDeep: Color(fixed: 0xD38E14),
        checkmark: Color(fixed: 0x5C3D0E),
        glass: GlassTint(
            glassTop: Color(fixed: 0x8DBF9F).opacity(0.4), glassBottom: Color(fixed: 0x2E5A45).opacity(0.5),
            sphereTint: Color(fixed: 0xEAF5E0), sphereEdge: Color(fixed: 0x2F5C46),
            filledLight: Color(fixed: 0xD3F2D4), filledMid: Color(fixed: 0x5DBB72), filledDeep: Color(fixed: 0x2E7D45)
        ),
        deepTop: Color(fixed: 0x15342B),
        deepBottom: Color(fixed: 0x0A1913),
        glows: [Color(fixed: 0x3FA66B), Color(fixed: 0xD9C35A), Color(fixed: 0x3E95AE)],
        squeeze: 0.14,
        bloomDelay: 0.18,
        bloomDuration: 0.85,
        closeDuration: 0.5,
        shedCount: 4...5,
        fallingSize: 11...19
    )
}

extension DS {
    enum Flower {
        /// 全部終わったとき、上から花びらが降る時間（この間に少しずつ降り始める）
        static let celebrationSpread: TimeInterval = 1.8
    }
}
