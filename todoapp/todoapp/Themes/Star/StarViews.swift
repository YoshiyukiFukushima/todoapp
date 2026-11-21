//
//  StarViews.swift
//  todoapp
//
//  星座のテーマ：灯る星（チェック）、夜空の背景、星座の形。
//  チェックすると星が灯り、光が夜空の星まで飛んでいって点灯する。全部終えると星が線でつながる。
//

import SwiftUI

extension DS {
    enum Star {
        // MARK: 夜空
        static let skyTop = Color(fixed: 0x0B1026)
        static let skyBottom = Color(fixed: 0x05070F)
        static let skyGlow = Color(fixed: 0x2A2F6E)

        // MARK: カード（夜のガラス）
        static let glass = GlassTint(
            glassTop: Color(fixed: 0x2E3250).opacity(0.85), glassBottom: Color(fixed: 0x161929).opacity(0.85),
            sphereTint: Color(fixed: 0xC9CFF0), sphereEdge: Color(fixed: 0x2A2F52),
            filledLight: Color(fixed: 0xFFF1C9), filledMid: Color(fixed: 0xE9B65A), filledDeep: Color(fixed: 0x9C6B1E)
        )

        // MARK: 星
        /// まだ灯っていない星（チェックの輪郭・夜空の暗い星）
        static let unlit = Color(fixed: 0x8A90AC)
        static let unlitDim = Color(fixed: 0x4E5472)
        /// 灯った星
        static let goldLight = Color(fixed: 0xFFF4D6)
        static let gold = Color(fixed: 0xF5C26B)
        static let goldDeep = Color(fixed: 0xD9963A)
        static let glow = Color(fixed: 0xFFDFA0)
        /// 星座の線と名前
        static let line = Color(fixed: 0xC6CCEA)

        // MARK: 動き
        /// 光が夜空の星まで飛ぶ時間
        static let flightDuration: TimeInterval = 0.65
        /// 星座の線を 1 本引く時間と、次の線までの間
        static let lineDuration: TimeInterval = 0.35
        static let lineStagger: TimeInterval = 0.28
    }
}

// MARK: - 灯る星（チェック）

/// 4 本の光の星。未完了は細い輪郭、完了は金色に灯る
struct StarFace: View {
    let isLit: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                // 灯ったときのまわりの光
                Circle()
                    .fill(RadialGradient(colors: [DS.Star.glow.opacity(0.55), .clear],
                                         center: .center, startRadius: 0, endRadius: size * 0.6))
                    .frame(width: size * 1.3, height: size * 1.3)
                    .opacity(isLit ? 1 : 0)
                SparkleShape()
                    .stroke(DS.Star.unlit, style: StrokeStyle(lineWidth: max(1, size * 0.05), lineJoin: .round))
                    .opacity(isLit ? 0 : 1)
                SparkleShape()
                    .fill(RadialGradient(colors: [DS.Star.goldLight, DS.Star.gold, DS.Star.goldDeep],
                                         center: .center, startRadius: 0, endRadius: size * 0.5))
                    .overlay {
                        SparkleShape().stroke(DS.Star.goldLight.opacity(0.9), lineWidth: max(0.8, size * 0.035))
                    }
                    .opacity(isLit ? 1 : 0)
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - 星座の形

/// 星座：星の位置（0〜1 の枠の中）と、つなぐ線
struct Constellation {
    let name: String
    let stars: [CGPoint]
    let lines: [(Int, Int)]

    /// その日のタスクの数に合う星座（7 より多ければ北斗七星）
    static func forTaskCount(_ count: Int) -> Constellation? {
        switch count {
        case ..<1: nil
        case 1: .firstStar
        case 2: .gemini
        case 3: .summerTriangle
        case 4: .southernCross
        case 5: .cassiopeia
        case 6: .pleiades
        default: .bigDipper
        }
    }

    static let firstStar = Constellation(name: "一番星", stars: [CGPoint(x: 0.5, y: 0.45)], lines: [])
    static let gemini = Constellation(name: "ふたご座", stars: [CGPoint(x: 0.38, y: 0.3), CGPoint(x: 0.62, y: 0.42)],
                                      lines: [(0, 1)])
    static let summerTriangle = Constellation(
        name: "夏の大三角",
        stars: [CGPoint(x: 0.25, y: 0.2), CGPoint(x: 0.75, y: 0.15), CGPoint(x: 0.55, y: 0.85)],
        lines: [(0, 1), (1, 2), (2, 0)])
    static let southernCross = Constellation(
        name: "みなみじゅうじ座",
        stars: [CGPoint(x: 0.5, y: 0.05), CGPoint(x: 0.28, y: 0.45), CGPoint(x: 0.7, y: 0.4), CGPoint(x: 0.53, y: 0.95)],
        lines: [(0, 3), (1, 2)])
    static let cassiopeia = Constellation(
        name: "カシオペヤ座",
        stars: [CGPoint(x: 0.04, y: 0.18), CGPoint(x: 0.28, y: 0.78), CGPoint(x: 0.5, y: 0.38),
                CGPoint(x: 0.72, y: 0.88), CGPoint(x: 0.96, y: 0.12)],
        lines: [(0, 1), (1, 2), (2, 3), (3, 4)])
    static let pleiades = Constellation(
        name: "すばる",
        stars: [CGPoint(x: 0.3, y: 0.35), CGPoint(x: 0.48, y: 0.18), CGPoint(x: 0.62, y: 0.38),
                CGPoint(x: 0.5, y: 0.55), CGPoint(x: 0.34, y: 0.72), CGPoint(x: 0.7, y: 0.78)],
        lines: [(0, 1), (1, 2), (2, 3), (3, 0), (3, 4), (2, 5)])
    static let bigDipper = Constellation(
        name: "北斗七星",
        stars: [CGPoint(x: 0.02, y: 0.25), CGPoint(x: 0.18, y: 0.2), CGPoint(x: 0.33, y: 0.3), CGPoint(x: 0.47, y: 0.45),
                CGPoint(x: 0.52, y: 0.85), CGPoint(x: 0.85, y: 0.92), CGPoint(x: 0.9, y: 0.5)],
        lines: [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 3)])
}

// MARK: - 夜空の背景（小さな星がまたたく）

struct StarfieldBackdrop: View {
    var isAnimated: Bool

    private static let dust: [SkyDust] = {
        var seed: UInt64 = 0x57A2
        func next() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double(seed >> 33) / Double(1 << 31)
        }
        return (0..<90).map { _ in
            SkyDust(x: next(), y: next(), radius: 0.4 + next() * 1.1, brightness: 0.25 + next() * 0.6,
                    speed: 0.6 + next() * 2.2, phase: next() * .pi * 2)
        }
    }()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(colors: [DS.Star.skyTop, DS.Star.skyBottom], startPoint: .top, endPoint: .bottom)
                Circle()
                    .fill(DS.Star.skyGlow.opacity(0.35))
                    .frame(width: proxy.size.width * 1.2)
                    .blur(radius: proxy.size.width * 0.35)
                    .position(x: proxy.size.width * 0.85, y: proxy.size.height * 0.1)
                if isAnimated {
                    TimelineView(.animation(minimumInterval: 1 / 20)) { timeline in
                        dustCanvas(time: timeline.date.timeIntervalSinceReferenceDate)
                    }
                } else {
                    dustCanvas(time: 0)
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func dustCanvas(time: TimeInterval) -> some View {
        Canvas { context, size in
            for dot in Self.dust {
                let twinkle = 0.65 + 0.35 * sin(time * dot.speed + dot.phase)
                let rect = CGRect(x: dot.x * size.width - dot.radius, y: dot.y * size.height - dot.radius,
                                  width: dot.radius * 2, height: dot.radius * 2)
                context.fill(Circle().path(in: rect), with: .color(.white.opacity(dot.brightness * twinkle)))
            }
        }
    }
}

private struct SkyDust {
    let x: Double
    let y: Double
    let radius: Double
    let brightness: Double
    let speed: Double
    let phase: Double
}
