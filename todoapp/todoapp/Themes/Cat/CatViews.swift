//
//  CatViews.swift
//  todoapp
//
//  ねこのテーマの色・形：肉球、ねこの手、ねこの顔、肉球のチェック、背景の足あと。
//  チェックすると下からねこの手が伸びてきて、気まぐれな向き・ずれで肉球のスタンプを押す（CatEffects）。
//  形は 1 枚の絵の座標（ねこの手は 70×120、顔は 120×84）で書き、表示する大きさに合わせて縮める。
//

import SwiftUI

extension DS {
    enum Cat {
        // MARK: 背景
        static let deepTop = Color(fixed: 0x3A2438)
        static let deepBottom = Color(fixed: 0x1A111A)
        static let glows: [(Color, Double)] = [
            (Color(fixed: 0xD4537E), 0.55), (Color(fixed: 0x7F77DD), 0.5), (Color(fixed: 0xC98A5E), 0.3),
        ]

        // MARK: 毛と肉球
        static let furLight = Color(fixed: 0xFFFDF8)
        static let furMid = Color(fixed: 0xF6EBD8)
        static let furDeep = Color(fixed: 0xD9C4A2)
        static let furLine = Color(fixed: 0xC9B48F)
        static let furStroke = Color(fixed: 0xD2BC98)
        static let padLight = Color(fixed: 0xFCDCE6)
        static let padMid = Color(fixed: 0xF2A6BE)
        static let padDeep = Color(fixed: 0xDE7F9F)
        /// スタンプのインク（白い丸の上でもはっきり見える濃さ）
        static let inkLight = Color(fixed: 0xF08DB0)
        static let inkDeep = Color(fixed: 0xC9537E)
        static let face = Color(fixed: 0x4A1B0C)
        static let speech = Color(fixed: 0x72243E)

        static let glass = GlassTint(
            glassTop: Color(fixed: 0xC8A6C2).opacity(0.34), glassBottom: Color(fixed: 0x5A3A57).opacity(0.48),
            sphereTint: Color(fixed: 0xFBEAF0), sphereEdge: Color(fixed: 0x6B4A68),
            filledLight: padLight, filledMid: padMid, filledDeep: padDeep
        )

        // MARK: 動き
        /// ねこの手が伸びて、押して、戻るまで
        static let armDuration: TimeInterval = 1.5
        /// タップしてから肉球のスタンプが付くまで（ねこの手が押しきったとき）
        static let stampDelay: TimeInterval = 0.82
        /// 全部終わってから、ねこが顔を出すまで
        static let peekDelay: TimeInterval = 1.2
        static let peekDuration: TimeInterval = 4.2
    }
}

// MARK: - 気まぐれなスタンプの押し方

/// 肉球のスタンプの向き・ずれ・大きさ。タスクごとに決まる
struct PawStamp: Equatable {
    /// 傾き（度）
    let angle: Double
    /// ずれ（チェックの大きさに対する割合）
    let dx: Double
    let dy: Double
    let scale: Double

    init(seed: UInt64) {
        var random = ThemeSeed(seed)
        // たいていは少し傾くだけ。ときどき大きく傾いたり、はみ出したりする
        let isWhimsical = random.next() < 0.25
        let tilt = isWhimsical ? random.next(in: 28...50) : random.next(in: 0...24)
        angle = random.next() < 0.5 ? -tilt : tilt
        let shift = isWhimsical ? 0.2 : 0.11
        dx = random.next(in: -shift...shift)
        dy = random.next(in: -shift...shift)
        scale = random.next(in: 0.92...1.08)
    }
}

// MARK: - 形

/// 肉球（大きな肉球 1 つと、指の肉球 4 つ）。座標はねこの手の絵（70×120）のもの
enum PawPads {
    /// スタンプとして切り出すときの範囲（ねこの手の絵の中）
    static let stampBox = CGRect(x: 12, y: 6, width: 46, height: 46)
    /// 肉球のまん中（ねこの手が押す点）
    static let center = CGPoint(x: 35, y: 29)

    static func path(_ transform: CGAffineTransform) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 35, y: 33))
        p.addCurve(to: CGPoint(x: 46.5, y: 44), control1: CGPoint(x: 42, y: 33), control2: CGPoint(x: 47.5, y: 38))
        p.addCurve(to: CGPoint(x: 35, y: 47.5), control1: CGPoint(x: 45.5, y: 49.5), control2: CGPoint(x: 40, y: 48))
        p.addCurve(to: CGPoint(x: 23.5, y: 44), control1: CGPoint(x: 30, y: 48), control2: CGPoint(x: 24.5, y: 49.5))
        p.addCurve(to: CGPoint(x: 35, y: 33), control1: CGPoint(x: 22.5, y: 38), control2: CGPoint(x: 28, y: 33))
        p.closeSubpath()
        let toes: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (18.5, 22.5, 4.4, 5.2, -25), (29.5, 15.5, 4.6, 5.4, -8), (40.5, 15.5, 4.6, 5.4, 8), (51.5, 22.5, 4.4, 5.2, 25),
        ]
        for (x, y, rx, ry, deg) in toes {
            let rotate = CGAffineTransform(translationX: x, y: y)
                .rotated(by: deg * .pi / 180)
            p.addPath(Path(ellipseIn: CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2)), transform: rotate)
        }
        return p.applying(transform)
    }
}

/// 絵の座標（box）を、rect にぴったり収める変換
private func fit(_ box: CGRect, in rect: CGRect) -> CGAffineTransform {
    let scale = min(rect.width / box.width, rect.height / box.height)
    return CGAffineTransform(translationX: rect.midX, y: rect.midY)
        .scaledBy(x: scale, y: scale)
        .translatedBy(x: -box.midX, y: -box.midY)
}

/// スタンプの肉球
struct PawPrintShape: Shape {
    func path(in rect: CGRect) -> Path {
        PawPads.path(fit(PawPads.stampBox, in: rect))
    }
}

/// ねこの手の形（腕・手のひら・指）。腕は長めにして、カードの下からはみ出さないようにする
private struct CatArmShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 18, y: 44))
        p.addQuadCurve(to: CGPoint(x: 52, y: 44), control: CGPoint(x: 35, y: 52))
        p.addLine(to: CGPoint(x: 54, y: 240))
        p.addLine(to: CGPoint(x: 16, y: 240))
        p.closeSubpath()
        p.addEllipse(in: CGRect(x: 13, y: 15, width: 44, height: 38))
        for (x, y, r) in [(17.5, 22.0, 8.3), (29, 14.5, 8.8), (41, 14.5, 8.8), (52.5, 22, 8.3)] as [(CGFloat, CGFloat, CGFloat)] {
            p.addEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
        }
        return p.applying(CGAffineTransform(scaleX: rect.width / CatArmView.box.width, y: rect.height / CatArmView.box.height))
    }
}

// MARK: - ねこの手

/// ふわふわの白いねこの手（上が指先）。肉球は下（タスク）に向いているので、見えるのは手の甲。
/// 肉球のまん中が PawPads.center（ここでチェックを押す）
struct CatArmView: View {
    static let box = CGRect(x: 0, y: 0, width: 70, height: 240)

    var body: some View {
        Canvas { context, size in
            let t = CGAffineTransform(scaleX: size.width / Self.box.width, y: size.height / Self.box.height)
            let s = size.width / Self.box.width
            let arm = CatArmShape().path(in: CGRect(origin: .zero, size: size))
            context.stroke(arm, with: .color(DS.Cat.furLine), lineWidth: 2.6 * s)
            context.fill(arm, with: .radialGradient(
                Gradient(colors: [DS.Cat.furLight, DS.Cat.furMid, DS.Cat.furDeep]),
                center: CGPoint(x: 31 * s, y: 26 * s), startRadius: 0, endRadius: 80 * s))
            // 手の甲：指のすき間（指先から手のひらへ）と、腕の毛のすじ
            var knuckles = Path()
            for (a, c, b) in [((23.3, 9.0), (22.6, 17.0), (24.5, 27.0)), ((35, 6.5), (35, 15.0), (35, 25.0)),
                              ((46.7, 9.0), (47.4, 17.0), (45.5, 27.0))]
                as [((CGFloat, CGFloat), (CGFloat, CGFloat), (CGFloat, CGFloat))] {
                knuckles.move(to: CGPoint(x: a.0, y: a.1))
                knuckles.addQuadCurve(to: CGPoint(x: b.0, y: b.1), control: CGPoint(x: c.0, y: c.1))
            }
            context.stroke(knuckles.applying(t), with: .color(DS.Cat.furLine),
                           style: StrokeStyle(lineWidth: 1.5 * s, lineCap: .round))
            var fur = Path()
            for (a, b) in [((20.0, 60.0), (21.0, 72.0)), ((50, 60), (49, 72)), ((27, 44), (28, 50)), ((43, 44), (42, 50))]
                as [((CGFloat, CGFloat), (CGFloat, CGFloat))] {
                fur.move(to: CGPoint(x: a.0, y: a.1))
                fur.addLine(to: CGPoint(x: b.0, y: b.1))
            }
            context.stroke(fur.applying(t), with: .color(DS.Cat.furStroke), style: StrokeStyle(lineWidth: 1 * s, lineCap: .round))
            // 指先のふわっとした光
            for rect in [CGRect(x: 12, y: 18, width: 7, height: 4), CGRect(x: 24, y: 9, width: 7, height: 4),
                         CGRect(x: 36, y: 9, width: 7, height: 4), CGRect(x: 48, y: 18, width: 7, height: 4)] {
                context.fill(Path(ellipseIn: rect.applying(t)), with: .color(.white.opacity(0.7)))
            }
        }
    }
}

// MARK: - ねこの顔（全部終わったとき、下から顔を出す）

struct CatFaceView: View {
    static let box = CGRect(x: 0, y: 0, width: 120, height: 84)

    var body: some View {
        Canvas { context, size in
            let s = size.width / Self.box.width
            let t = CGAffineTransform(scaleX: s, y: s)
            var head = Path()
            head.move(to: CGPoint(x: 22, y: 46)); head.addLine(to: CGPoint(x: 26, y: 8)); head.addLine(to: CGPoint(x: 52, y: 30)); head.closeSubpath()
            // 右の耳は左の耳と同じ回り方で描く（逆回りだと、頭と重なったところが抜けてしまう）
            head.move(to: CGPoint(x: 98, y: 46)); head.addLine(to: CGPoint(x: 68, y: 30)); head.addLine(to: CGPoint(x: 94, y: 8)); head.closeSubpath()
            head.addEllipse(in: CGRect(x: 14, y: 24, width: 92, height: 72))
            head = head.applying(t)
            context.stroke(head, with: .color(DS.Cat.furLine), style: StrokeStyle(lineWidth: 3 * s, lineJoin: .round))
            context.fill(head, with: .radialGradient(
                Gradient(colors: [DS.Cat.furLight, DS.Cat.furMid, DS.Cat.furDeep]),
                center: CGPoint(x: 54 * s, y: 30 * s), startRadius: 0, endRadius: 90 * s))

            var innerEars = Path()
            innerEars.move(to: CGPoint(x: 29, y: 17)); innerEars.addLine(to: CGPoint(x: 31, y: 34)); innerEars.addLine(to: CGPoint(x: 44, y: 29)); innerEars.closeSubpath()
            innerEars.move(to: CGPoint(x: 91, y: 17)); innerEars.addLine(to: CGPoint(x: 89, y: 34)); innerEars.addLine(to: CGPoint(x: 76, y: 29)); innerEars.closeSubpath()
            context.fill(innerEars.applying(t), with: .color(Color(fixed: 0xF4C0D1)))

            // にっこり閉じた目
            var eyes = Path()
            eyes.move(to: CGPoint(x: 36, y: 55)); eyes.addQuadCurve(to: CGPoint(x: 48, y: 55), control: CGPoint(x: 42, y: 49))
            eyes.move(to: CGPoint(x: 72, y: 55)); eyes.addQuadCurve(to: CGPoint(x: 84, y: 55), control: CGPoint(x: 78, y: 49))
            context.stroke(eyes.applying(t), with: .color(DS.Cat.face), style: StrokeStyle(lineWidth: 2.6 * s, lineCap: .round))

            var nose = Path()
            nose.move(to: CGPoint(x: 57, y: 61)); nose.addQuadCurve(to: CGPoint(x: 63, y: 61), control: CGPoint(x: 60, y: 59))
            nose.addQuadCurve(to: CGPoint(x: 57, y: 61), control: CGPoint(x: 60, y: 65))
            context.fill(nose.applying(t), with: .color(Color(fixed: 0xE889A6)))

            var mouth = Path()
            mouth.move(to: CGPoint(x: 54, y: 67)); mouth.addQuadCurve(to: CGPoint(x: 60, y: 66), control: CGPoint(x: 57, y: 70))
            mouth.addQuadCurve(to: CGPoint(x: 66, y: 67), control: CGPoint(x: 63, y: 70))
            context.stroke(mouth.applying(t), with: .color(DS.Cat.face), style: StrokeStyle(lineWidth: 1.6 * s, lineCap: .round))

            var whiskers = Path()
            for (a, b) in [((26.0, 62.0), (40.0, 64.0)), ((27, 70), (40, 68)), ((94, 62), (80, 64)), ((93, 70), (80, 68))] as [((CGFloat, CGFloat), (CGFloat, CGFloat))] {
                whiskers.move(to: CGPoint(x: a.0, y: a.1)); whiskers.addLine(to: CGPoint(x: b.0, y: b.1))
            }
            context.stroke(whiskers.applying(t), with: .color(Color(fixed: 0xB4A07E)), style: StrokeStyle(lineWidth: 1.1 * s, lineCap: .round))

            for x in [32.0, 76.0] {
                context.fill(Path(ellipseIn: CGRect(x: x, y: 61.5, width: 12, height: 7).applying(t)),
                             with: .color(Color(fixed: 0xF4C0D1).opacity(0.75)))
            }
        }
    }
}

/// 「にゃ〜」の吹き出し
struct CatSpeechBubble: View {
    var body: some View {
        Text("にゃ〜")
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(DS.Cat.speech)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(.white, in: Capsule())
    }
}

// MARK: - 肉球のチェック

/// 未完了はすりガラスの丸。完了すると、白い丸に肉球のスタンプが気まぐれな向き・ずれで付く
struct CatPawCheck: View {
    let isCompleted: Bool
    let stamp: PawStamp
    var isAnimated = true

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                Circle().fill(RadialGradient(
                    colors: isCompleted ? [.white, Color(fixed: 0xFBEAF0)] : [.white.opacity(0.5), .white.opacity(0.08)],
                    center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: size * 0.62))
                Circle().strokeBorder(.white.opacity(isCompleted ? 1 : 0.6), lineWidth: 1)
                PawPrintShape()
                    .fill(LinearGradient(colors: [DS.Cat.inkLight, DS.Cat.inkDeep],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: size * 0.9, height: size * 0.9)
                    .scaleEffect(stamp.scale * (isCompleted ? 1 : 0.4))
                    .rotationEffect(.degrees(stamp.angle))
                    .offset(x: size * stamp.dx, y: size * stamp.dy)
                    .opacity(isCompleted ? 1 : 0)
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .animation(animation, value: isCompleted)
    }

    /// ねこの手が押しきったところで、ぽんと付く。外すときはすっと消える
    private var animation: Animation? {
        guard isAnimated else { return nil }
        return isCompleted
            ? .spring(response: 0.36, dampingFraction: 0.5).delay(DS.Cat.stampDelay)
            : .easeOut(duration: 0.25)
    }
}

// MARK: - 背景の足あと（ふっと浮かんで、ふっと消える）

struct CatFootprints: View {
    let time: TimeInterval

    private static let dots = AmbientDot.make(count: 9, seed: 0xCA7)

    var body: some View {
        Canvas { context, size in
            for (index, dot) in Self.dots.enumerated() {
                // 少しずつ時間をずらして、浮かんでは消える
                let cycle = (time * 0.12 * dot.speed + dot.phase).truncatingRemainder(dividingBy: .pi * 2)
                let opacity = 0.05 + 0.1 * max(sin(cycle), 0)
                let side = size.width * (0.05 + 0.04 * dot.size)
                let rect = CGRect(x: dot.x * size.width - side / 2, y: dot.y * size.height - side / 2, width: side, height: side)
                var c = context
                c.translateBy(x: rect.midX, y: rect.midY)
                c.rotate(by: .degrees(Double(index % 2 == 0 ? -20 : 20) + dot.phase * 5))
                c.fill(PawPrintShape().path(in: CGRect(x: -side / 2, y: -side / 2, width: side, height: side)),
                       with: .color(DS.Cat.padLight.opacity(opacity)))
            }
        }
    }
}
