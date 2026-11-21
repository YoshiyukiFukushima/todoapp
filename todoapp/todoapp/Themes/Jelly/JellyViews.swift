//
//  JellyViews.swift
//  todoapp
//
//  ゼリーのテーマの色・形：ゼリー、色に染まるチェック、背景の小さな泡。
//  チェックすると、ゼリーが一度ぎゅっとつぶれてから、ぷるんぷるんと何度も揺れて止まる（揺れは CheckButton のキーフレーム）。
//  揺れているあいだに、透明なゼリーがぶどう・オレンジ・メロンの色に染まり、中にチェックが浮かぶ（JellyCheck）。
//  カード全体も少しだけ揺れる（TaskRowView）。演出の層はない（短く終わるテーマ）。
//  ウィジェットでも使う（チェックと背景）。
//

import SwiftUI

extension DS {
    enum Jelly {
        // MARK: 背景（夜のガラスの器）
        static let deepTop = Color(fixed: 0x1C2340)
        static let deepBottom = Color(fixed: 0x111628)
        static let glows: [(Color, Double)] = [
            (Color(fixed: 0x9B5DE5), 0.5), (Color(fixed: 0xFF9A3C), 0.3), (Color(fixed: 0x7FD65A), 0.32),
        ]

        static let glass = GlassTint(
            glassTop: Color(fixed: 0xBFD0F0).opacity(0.3), glassBottom: Color(fixed: 0x34406A).opacity(0.5),
            sphereTint: Color(fixed: 0xF2F6FF), sphereEdge: Color(fixed: 0x56628E),
            filledLight: Color(fixed: 0xD9B8FF), filledMid: Color(fixed: 0x9B5DE5), filledDeep: Color(fixed: 0x6A35B0)
        )

        // MARK: 動き
        /// つぶれて、ぷるぷる揺れて止まるまで
        static let wobbleDuration: TimeInterval = 0.95
        /// 色に染まる時間
        static let tintDuration: TimeInterval = 0.7
    }
}

// MARK: - 味（タスクごとに決まる）

struct JellyFlavor: Equatable {
    let light: Color
    let mid: Color
    let deep: Color

    static let grape = JellyFlavor(light: Color(fixed: 0xDCC0FF), mid: Color(fixed: 0x9B5DE5), deep: Color(fixed: 0x6532AC))
    static let orange = JellyFlavor(light: Color(fixed: 0xFFD7A3), mid: Color(fixed: 0xFF9A3C), deep: Color(fixed: 0xD3631A))
    static let melon = JellyFlavor(light: Color(fixed: 0xD2F7BC), mid: Color(fixed: 0x7FD65A), deep: Color(fixed: 0x45982F))

    static let all: [JellyFlavor] = [.grape, .orange, .melon]

    static func pick(seed: UInt64) -> JellyFlavor {
        var random = ThemeSeed(seed ^ 0x7E11)
        return all[Int(random.next() * Double(all.count)) % all.count]
    }
}

// MARK: - 形

/// ゼリー（下が少し広い、まるい山）。rect いっぱいに描く
struct JellyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + w * 0.04, y: rect.maxY - h * 0.1))
        p.addCurve(to: CGPoint(x: rect.minX + w * 0.16, y: rect.minY + h * 0.22),
                   control1: CGPoint(x: rect.minX, y: rect.maxY - h * 0.45),
                   control2: CGPoint(x: rect.minX + w * 0.08, y: rect.minY + h * 0.32))
        p.addCurve(to: CGPoint(x: rect.maxX - w * 0.16, y: rect.minY + h * 0.22),
                   control1: CGPoint(x: rect.minX + w * 0.3, y: rect.minY - h * 0.02),
                   control2: CGPoint(x: rect.maxX - w * 0.3, y: rect.minY - h * 0.02))
        p.addCurve(to: CGPoint(x: rect.maxX - w * 0.04, y: rect.maxY - h * 0.1),
                   control1: CGPoint(x: rect.maxX - w * 0.08, y: rect.minY + h * 0.32),
                   control2: CGPoint(x: rect.maxX, y: rect.maxY - h * 0.45))
        p.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.04, y: rect.maxY - h * 0.1),
                       control: CGPoint(x: rect.midX, y: rect.maxY + h * 0.04))
        p.closeSubpath()
        return p
    }
}

// MARK: - 色に染まるチェック

/// 未完了は透明なゼリー。完了すると味の色に染まり、中にチェックが浮かぶ
struct JellyCheck: View {
    let isCompleted: Bool
    let flavor: JellyFlavor
    var isAnimated = true

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                // 器に落ちる影
                Ellipse()
                    .fill(.black.opacity(0.25))
                    .frame(width: size * 0.86, height: size * 0.14)
                    .offset(y: size * 0.42)
                // 透明なゼリー
                JellyShape()
                    .fill(LinearGradient(colors: [.white.opacity(0.42), .white.opacity(0.1)],
                                         startPoint: .top, endPoint: .bottom))
                // 色に染まったゼリー
                JellyShape()
                    .fill(RadialGradient(colors: [flavor.light, flavor.mid, flavor.deep],
                                         center: UnitPoint(x: 0.4, y: 0.3), startRadius: 0, endRadius: size * 0.8))
                    .opacity(isCompleted ? 0.92 : 0)
                    .animation(isAnimated ? .easeInOut(duration: DS.Jelly.tintDuration).delay(0.08) : nil, value: isCompleted)
                JellyShape()
                    .stroke(.white.opacity(isCompleted ? 0.55 : 0.75), lineWidth: max(0.8, size * 0.035))
                // 中に閉じこめられた小さな泡
                Circle().fill(.white.opacity(0.55))
                    .frame(width: size * 0.07, height: size * 0.07)
                    .offset(x: size * 0.22, y: size * 0.18)
                Circle().fill(.white.opacity(0.4))
                    .frame(width: size * 0.05, height: size * 0.05)
                    .offset(x: -size * 0.24, y: size * 0.26)
                // 中に浮かぶチェック
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.42, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(color: flavor.deep.opacity(0.6), radius: 1, y: 0.5)
                    .opacity(isCompleted ? 0.95 : 0)
                    .scaleEffect(isCompleted ? 1 : 0.5)
                    .offset(y: isCompleted ? size * 0.04 : size * 0.18)
                    .animation(isAnimated
                               ? (isCompleted ? .spring(response: 0.5, dampingFraction: 0.55).delay(0.28) : .easeOut(duration: 0.2))
                               : nil,
                               value: isCompleted)
                // つや
                Capsule()
                    .fill(.white.opacity(0.75))
                    .frame(width: size * 0.12, height: size * 0.26)
                    .rotationEffect(.degrees(28))
                    .offset(x: -size * 0.22, y: -size * 0.08)
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }
}

// MARK: - 背景の小さな泡（色つきで、ゆっくり昇る）

struct JellySoda: View {
    let time: TimeInterval

    private static let dots = AmbientDot.make(count: 24, seed: 0x7E11F)

    var body: some View {
        Canvas { context, size in
            let travel = size.height + 30
            for (index, dot) in Self.dots.enumerated() {
                let distance = (time * 12 * dot.speed + dot.y * travel).truncatingRemainder(dividingBy: travel)
                let y = size.height + 15 - distance
                let x = dot.x * size.width + sin(time * 1.1 * dot.speed + dot.phase) * 6
                let r = 1.5 + dot.size * 3.5
                let color = JellyFlavor.all[index % JellyFlavor.all.count].light
                context.stroke(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                               with: .color(color.opacity(0.22)), lineWidth: 0.8)
            }
        }
    }
}
