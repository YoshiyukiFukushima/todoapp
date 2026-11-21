//
//  StampViews.swift
//  todoapp
//
//  判子（スタンプ）のテーマ：和紙のカードと背景、朱色の「済」の印、判子が降りてくる動き。
//  判子に合わせて、ここだけガラスではなく和紙のカードにする。
//

import SwiftUI

extension DS {
    enum Stamp {
        // MARK: 和紙
        static let paperTop = Color(fixed: 0xFBF7EF)
        static let paperBottom = Color(fixed: 0xF5EFE3)
        static let paperEdge = Color(fixed: 0xE0D4BE)
        /// カードの下にできる、紙の厚みの影
        static let paperShadow = Color(fixed: 0xCDBE9E)
        /// 紙のすき目（繊維）
        static let fiber = Color(fixed: 0xB9A888)
        static let backgroundTop = Color(fixed: 0xEDE5D5)
        static let backgroundBottom = Color(fixed: 0xE2D7C2)

        // MARK: 印
        /// 朱色（押したて／にじんだあと）
        static let vermilion = Color(fixed: 0xC8462F)
        static let vermilionDeep = Color(fixed: 0xA8341F)
        /// 未完了の点線の丸
        static let guide = Color(fixed: 0xB8AA8E)

        // MARK: 動き
        /// 判子が降りてきて、紙に当たるまで
        static let pressDelay: TimeInterval = 0.32
        /// 押したあと朱色がにじむ時間
        static let bleedDuration: TimeInterval = 0.9
        /// 押した瞬間に、カードが沈む深さ（pt）
        static let sinkDepth: CGFloat = 3
    }
}

// MARK: - 和紙の面（カード・丸・カプセル）

struct WashiSurface<S: InsettableShape>: View {
    let shape: S
    var isPressed = false
    /// すき目の並びを変える種
    var seed: UInt64 = 0x5A5A

    var body: some View {
        ZStack {
            shape.fill(LinearGradient(colors: [DS.Stamp.paperTop, DS.Stamp.paperBottom], startPoint: .top, endPoint: .bottom))
            WashiFibers(seed: seed, density: 0.9)
                .clipShape(shape)
            shape.strokeBorder(DS.Stamp.paperEdge, lineWidth: 1)
        }
        // 紙の厚み（真下に少しだけずれた影）
        .background {
            shape.fill(DS.Stamp.paperShadow).offset(y: isPressed ? 1 : 3)
        }
    }
}

/// 和紙のすき目：細く短い繊維が、ばらばらの向きに薄く散らばる
struct WashiFibers: View {
    var seed: UInt64
    /// 100 × 100 pt あたりの繊維の数の目安
    var density: Double

    var body: some View {
        Canvas { context, size in
            var state = seed
            func next() -> Double {
                state = state &* 6364136223846793005 &+ 1442695040888963407
                return Double(state >> 33) / Double(1 << 31)
            }
            let count = Int(Double(size.width * size.height) / 10_000 * 14 * density)
            for _ in 0..<min(count, 400) {
                let x = next() * size.width, y = next() * size.height
                let length = 4 + next() * 12
                let angle = next() * .pi
                let bend = (next() - 0.5) * 6
                var path = Path()
                path.move(to: CGPoint(x: x, y: y))
                path.addQuadCurve(to: CGPoint(x: x + cos(angle) * length, y: y + sin(angle) * length),
                                  control: CGPoint(x: x + cos(angle) * length / 2 + bend, y: y + sin(angle) * length / 2 - bend))
                context.stroke(path, with: .color(DS.Stamp.fiber.opacity(0.08 + next() * 0.12)), lineWidth: 0.5 + next() * 0.4)
            }
        }
        .allowsHitTesting(false)
    }
}

/// 和紙の画面の背景
struct WashiBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [DS.Stamp.backgroundTop, DS.Stamp.backgroundBottom], startPoint: .top, endPoint: .bottom)
            WashiFibers(seed: 0xBEEF, density: 0.6)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

// MARK: - 朱色の「済」の印

/// 押した印。くっきりした線で、bleed（0〜1）で朱色がふちにじわっとにじむ。
struct StampMark: View {
    /// 傾き（度）。押すたびに少し変わる
    var tilt: Double
    /// にじみ（0：押したて、1：にじみきった）
    var bleed: Double = 1

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                // にじみ：同じ印を少しだけぼかして、すぐ外側に薄く広げる（線はくっきりのまま）
                face(size: size)
                    .blur(radius: 0.6 + 0.9 * bleed)
                    .opacity(0.3 * bleed)
                    .scaleEffect(1 + 0.025 * bleed)
                face(size: size)
            }
            .rotationEffect(.degrees(tilt))
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .accessibilityHidden(true)
    }

    private func face(size: CGFloat) -> some View {
        let ink = LinearGradient(colors: [DS.Stamp.vermilion, DS.Stamp.vermilionDeep],
                                 startPoint: .topLeading, endPoint: .bottomTrailing)
        return ZStack {
            Circle().strokeBorder(ink, lineWidth: size * 0.085)
            Circle().strokeBorder(ink, lineWidth: size * 0.025).padding(size * 0.14)
            Text("済")
                .font(.system(size: size * 0.5, weight: .heavy, design: .serif))
                .foregroundStyle(ink)
                .offset(y: -size * 0.01)
        }
        .frame(width: size, height: size)
    }
}

/// 未完了：薄い点線の丸（ここに押す、という目印）
struct StampGuide: View {
    var body: some View {
        Circle()
            .strokeBorder(DS.Stamp.guide, style: StrokeStyle(lineWidth: 1.4, dash: [3.5, 3]))
    }
}

extension StampMark {
    /// タスク名から、いつも同じ値を作る（起動し直しても変わらない）。傾きや、ろうそくのゆらめきのずれに使う
    static func stableSeed(for text: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }

    static func stableTilt(for text: String) -> Double {
        Double(stableSeed(for: text) % 21) - 10
    }
}

// MARK: - 判子が影を落としながら上から降りてくる

/// trigger が変わるたびに、判子が上から降りてきて紙に当たる（当たったら消え、そこに印が残る）
struct StampDescent: View {
    let trigger: Int
    let tilt: Double

    private struct Pose {
        /// 1 で紙に当たった高さ、大きいほど上（手前）にある
        var height: CGFloat = 0
        var opacity: Double = 0
    }

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            Color.clear
                .keyframeAnimator(initialValue: Pose(), trigger: trigger) { content, pose in
                    ZStack {
                        // 影：判子が高いほど大きく、ぼんやり薄い。近づくほど小さく濃くなる
                        Circle()
                            .fill(Color.black.opacity(0.28 * (1 - Double(pose.height) * 0.6)))
                            .frame(width: size * (1 + pose.height * 0.35), height: size * (1 + pose.height * 0.35))
                            .blur(radius: 2 + pose.height * 7)
                            .offset(x: pose.height * 5, y: pose.height * 7)
                        // 判子の面（手前にあるほど大きく、少し上）
                        StampMark(tilt: tilt, bleed: 0)
                            .frame(width: size, height: size)
                            .scaleEffect(1 + pose.height * 0.45)
                            .offset(y: -pose.height * size * 0.9)
                    }
                    .opacity(pose.opacity)
                    .overlay { content }
                } keyframes: { _ in
                    KeyframeTrack(\.height) {
                        LinearKeyframe(1, duration: 0.01)
                        CubicKeyframe(0, duration: DS.Stamp.pressDelay - 0.01)
                    }
                    KeyframeTrack(\.opacity) {
                        LinearKeyframe(1, duration: 0.06)
                        LinearKeyframe(1, duration: DS.Stamp.pressDelay - 0.06)
                        LinearKeyframe(0, duration: 0.01)
                    }
                }
                .frame(width: size, height: size)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
