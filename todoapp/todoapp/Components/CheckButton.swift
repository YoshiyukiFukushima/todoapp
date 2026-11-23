//
//  CheckButton.swift
//  todoapp
//
//  タスクの完了チェック。タップ範囲は 44pt。完了時は弾み、触覚フィードバックを返す。
//  見た目と動きはテーマの描き方（ThemeStyle）で変わる。
//  - standard: 差し色の丸。小さく弾む
//  - bubble: シャボン玉。一度ふくらんでから縮み、はじける（輪と小さな泡は BubbleEffects が描く）
//  - flower: つぼみ。きゅっと縮んでから 6 枚の花びらがゆっくり開く（舞い落ちる花びらは FlowerEffects が描く）
//    外すと花びらが逆の順で閉じる
//  - stamp: 判子が影を落としながら上から降りてきて、くっきりした印が残り、朱色がじわっとにじむ
//  - candle: 火が横に吹かれたように消える（残り火と煙は CandleEffects が描く）
//  - constellation: 星が灯り、光が夜空の星へ飛ぶ（StarEffects が描く）
//  - water: しずくが落ちて当たると水玉に変わり、横につぶれてからぷるぷる揺れて戻る（しずくと波紋は WaterEffects が描く）
//  - fireworks: 玉がふるえながら縮んで光をため、ためきったところで光の筋が放射状に開く（花火は FireworksEffects が描く）
//  - balloon: 風船がぐらぐら揺れながらふくらみ、パンッと割れる（破片・紙吹雪・ひもは BalloonEffects が描く）
//  - jelly: ぎゅっとつぶれてから、ぷるんぷるん揺れて止まる。揺れるあいだに色に染まる（カードも TaskRowView で少し揺れる）
//  - paperPlane: 紙が折りたたまれて紙飛行機になり、少し沈む（飛んでいくのは PaperPlaneEffects が描く）
//  - shishiOdoshi: 水がたまって傾き、戻って石を打つ（「カコーン」は ShishiEffects が鳴らす）
//  - butterfly: さなぎが割れて羽化する（カードの右端へ飛んでとまるのは TaskRowView の ButterflyPerch）
//  - planet: 星くずが渦を巻いて集まり、惑星がぽんと生まれて、輪が広がる
//  - snowman: 雪玉が転がってきて、頭がぽすんと乗り、顔がついて、マフラーを巻く
//  - weather: 雲がふくらんで流れていき、うしろから太陽がのぼって、にっこり笑う
//  花・花火・ゼリー・ししおどし・ちょうちょは、完了しても行の中でチェックだけは薄くしない（TaskRowView）
//

import SwiftUI

struct CheckButton: View {
    let isCompleted: Bool
    let taskTitle: String
    let animationsEnabled: Bool
    /// タスクごとに決まったでたらめの種（花火・風船などの色）
    var seed: UInt64 = 0
    let action: () -> Void

    @Environment(\.dsStyle) private var style
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(BubbleEffects.self) private var bubbleEffects: BubbleEffects?
    @Environment(FlowerEffects.self) private var flowerEffects: FlowerEffects?
    @Environment(WaterEffects.self) private var waterEffects: WaterEffects?
    @Environment(CandleEffects.self) private var candleEffects: CandleEffects?
    @Environment(StarEffects.self) private var starEffects: StarEffects?
    /// 判子の傾き。押すたびに少し変わる（押すまではタスク名から決まった傾き）
    @State private var stampTilt: Double?
    @Environment(FireworksEffects.self) private var fireworksEffects: FireworksEffects?
    @Environment(BalloonEffects.self) private var balloonEffects: BalloonEffects?
    @Environment(PaperPlaneEffects.self) private var paperPlaneEffects: PaperPlaneEffects?
    @Environment(ShishiEffects.self) private var shishiEffects: ShishiEffects?
    @State private var bounceTrigger = 0
    @State private var globalFrame: CGRect = .zero
    /// 泡がはじける・しずくが当たるまでは、未完了の見た目のまま見せる
    @State private var isPopping = false

    var body: some View {
        // ゼリーは器に乗っているので、下を支点にしてつぶれる（アニメーションの中で使うので先に決めておく）
        let squashAnchor: UnitPoint = style == .jelly ? .bottom : .center
        Button {
            let willComplete = !isCompleted
            action()
            guard willComplete, animationsEnabled, !reduceMotion else { return }
            bounceTrigger += 1
            let center = CGPoint(x: globalFrame.midX, y: globalFrame.midY)
            switch style {
            case .standard:
                break
            case .bubble:
                isPopping = true
                bubbleEffects?.pop(at: center, radius: globalFrame.width / 2)
                Task {
                    try? await Task.sleep(for: .seconds(DS.Bubble.popDelay))
                    isPopping = false
                }
            case .flower(let kind):
                flowerEffects?.shed(kind, at: center, radius: globalFrame.width / 2)
            case .stamp:
                stampTilt = .random(in: -14...14)
                isPopping = true
                Task {
                    try? await Task.sleep(for: .seconds(DS.Stamp.pressDelay))
                    isPopping = false
                }
            case .candle:
                // 芯の先（ろうそくの上のあたり）から煙を出す
                candleEffects?.snuff(wick: CGPoint(x: globalFrame.midX, y: globalFrame.midY - globalFrame.height * (0.19 - CandleFace.drop)))
            case .constellation:
                starEffects?.launch(from: center)
            case .water:
                isPopping = true
                waterEffects?.drop(at: center, radius: globalFrame.width / 2)
                Task {
                    try? await Task.sleep(for: .seconds(DS.Water.fallDuration))
                    isPopping = false
                }
            case .fireworks:
                fireworksEffects?.burst(at: center, radius: globalFrame.width / 2, color: FireworkColor.pick(seed: seed))
            case .balloon:
                balloonEffects?.pop(at: center, size: globalFrame.width, color: BalloonColor.pick(seed: seed))
            case .paperPlane:
                paperPlaneEffects?.launch(from: center, size: globalFrame.width)
            case .shishiOdoshi:
                shishiEffects?.knock(at: center, size: globalFrame.width)
            // ゼリーはチェックとカードの揺れだけ。ちょうちょはカードの上（ButterflyPerch）で飛ぶ
            // 惑星・雪だるま・くもり晴れもチェックの中で完結する
            case .jelly, .butterfly, .planet, .snowman, .weather:
                break
            }
        } label: {
            CheckMarkFace(style: style, isCompleted: isCompleted && !isPopping,
                          isAnimated: animationsEnabled && !reduceMotion,
                          tilt: stampTilt ?? StampMark.stableTilt(for: taskTitle),
                          seed: seed, candlePhase: Double(titleSeed % 628) / 100)
                .frame(width: style.checkboxSize, height: style.checkboxSize)
                .overlay {
                    if style == .stamp {
                        StampDescent(trigger: bounceTrigger, tilt: stampTilt ?? 0)
                    }
                }
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { globalFrame = $0 }
                .keyframeAnimator(initialValue: CheckScale(), trigger: bounceTrigger) { content, scale in
                    content.scaleEffect(x: scale.x, y: scale.y, anchor: squashAnchor)
                } keyframes: { _ in
                    KeyframeTrack(\.x) { widthKeyframes }
                    KeyframeTrack(\.y) { heightKeyframes }
                }
                .frame(width: DS.Size.minTapTarget, height: DS.Size.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: isCompleted) { old, new in !old && new }
        .accessibilityLabel(isCompleted ? "未完了に戻す" : "完了にする")
        .accessibilityValue(taskTitle)
    }

    /// タスク名から決まった種（ろうそくのゆらめきをずらす。カードの明かりと合わせる）
    private var titleSeed: UInt64 { StampMark.stableSeed(for: taskTitle) }

    /// 横の伸び縮み。水滴だけは縦と別に動かして、つぶれてから揺れて戻る
    @KeyframeTrackContentBuilder<CGFloat>
    private var widthKeyframes: some KeyframeTrackContent<CGFloat> {
        switch style {
        case .water:
            // 落ちてくる間は待つ → 当たって横につぶれる → ぷるぷる揺れて戻る
            LinearKeyframe(1.0, duration: DS.Water.fallDuration)
            CubicKeyframe(1.36, duration: 0.07)
            CubicKeyframe(0.86, duration: 0.12)
            CubicKeyframe(1.1, duration: 0.11)
            CubicKeyframe(0.96, duration: 0.1)
            SpringKeyframe(1.0, duration: 0.2)
        case .jelly:
            // ぎゅっと横に広がってつぶれる → ぷるんぷるんと何度も揺れて止まる
            CubicKeyframe(1.3, duration: 0.09)
            CubicKeyframe(0.84, duration: 0.13)
            CubicKeyframe(1.16, duration: 0.13)
            CubicKeyframe(0.92, duration: 0.13)
            CubicKeyframe(1.07, duration: 0.13)
            CubicKeyframe(0.97, duration: 0.13)
            SpringKeyframe(1.0, duration: 0.2)
        default:
            uniformKeyframes
        }
    }

    @KeyframeTrackContentBuilder<CGFloat>
    private var heightKeyframes: some KeyframeTrackContent<CGFloat> {
        switch style {
        case .water:
            LinearKeyframe(1.0, duration: DS.Water.fallDuration)
            CubicKeyframe(0.66, duration: 0.07)
            CubicKeyframe(1.14, duration: 0.12)
            CubicKeyframe(0.92, duration: 0.11)
            CubicKeyframe(1.04, duration: 0.1)
            SpringKeyframe(1.0, duration: 0.2)
        case .jelly:
            CubicKeyframe(0.68, duration: 0.09)
            CubicKeyframe(1.18, duration: 0.13)
            CubicKeyframe(0.88, duration: 0.13)
            CubicKeyframe(1.08, duration: 0.13)
            CubicKeyframe(0.95, duration: 0.13)
            CubicKeyframe(1.02, duration: 0.13)
            SpringKeyframe(1.0, duration: 0.2)
        default:
            uniformKeyframes
        }
    }

    /// 縦横そろえて大きさだけ変える動き
    @KeyframeTrackContentBuilder<CGFloat>
    private var uniformKeyframes: some KeyframeTrackContent<CGFloat> {
        switch style {
        case .standard:
            SpringKeyframe(1.25, duration: 0.12)
            SpringKeyframe(1.0, duration: 0.25)
        case .bubble:
            // ふくらむ → 縮む（ここではじける）→ 元に戻る
            CubicKeyframe(1.35, duration: 0.16)
            CubicKeyframe(0.7, duration: DS.Bubble.popDelay - 0.16)
            SpringKeyframe(1.0, duration: 0.35, spring: .bouncy)
        case .flower(let kind):
            // きゅっと縮む → 少し待つ → 花びらが開くのに合わせて、ゆっくり元の大きさへ
            let spec = kind.spec
            CubicKeyframe(0.74, duration: spec.squeeze)
            CubicKeyframe(0.74, duration: spec.bloomDelay - spec.squeeze)
            SpringKeyframe(1.0, duration: spec.bloomDuration * 0.7, spring: .smooth)
        case .stamp:
            // 降りてくる間は待つ → 押した瞬間に少し沈む
            LinearKeyframe(1.0, duration: DS.Stamp.pressDelay)
            CubicKeyframe(0.9, duration: 0.05)
            SpringKeyframe(1.0, duration: 0.25)
        case .constellation:
            // きゅっと縮んで、ぱっと灯る
            CubicKeyframe(0.7, duration: 0.08)
            SpringKeyframe(1.3, duration: 0.16)
            SpringKeyframe(1.0, duration: 0.3, spring: .bouncy)
        case .fireworks:
            // 光をためるあいだ、ふるえながらだんだん縮む → ぎゅっと縮みきって → ぱっと開く
            // （ここの時間の合計は DS.Fireworks.chargeDuration と同じ 0.95 秒）
            CubicKeyframe(0.9, duration: 0.25)
            LinearKeyframe(0.84, duration: 0.07)
            LinearKeyframe(0.88, duration: 0.07)
            LinearKeyframe(0.8, duration: 0.07)
            LinearKeyframe(0.85, duration: 0.07)
            LinearKeyframe(0.76, duration: 0.07)
            LinearKeyframe(0.81, duration: 0.07)
            CubicKeyframe(0.64, duration: 0.28)
            SpringKeyframe(1.3, duration: 0.14)
            SpringKeyframe(1.0, duration: 0.4, spring: .bouncy)
        case .balloon:
            // 割れるまでは待つ → 割れた反動で、きゅっと縮んで戻る
            LinearKeyframe(1.0, duration: DS.Balloon.popDelay)
            CubicKeyframe(0.8, duration: 0.05)
            SpringKeyframe(1.0, duration: 0.3, spring: .bouncy)
        case .planet:
            // 星くずが集まるあいだは待つ → 惑星が生まれた瞬間にぽんとふくらむ
            LinearKeyframe(1.0, duration: DS.Planet.birthDuration * DS.Planet.formAt)
            CubicKeyframe(1.14, duration: 0.1)
            SpringKeyframe(1.0, duration: 0.35, spring: .bouncy)
        case .snowman:
            // 頭が乗るまで待つ → ぽすんと沈む
            LinearKeyframe(1.0, duration: DS.Snowman.headDelay)
            CubicKeyframe(0.92, duration: 0.06)
            SpringKeyframe(1.0, duration: 0.3, spring: .bouncy)
        case .water, .candle, .jelly, .paperPlane, .shishiOdoshi, .butterfly, .weather:
            // 動きはチェックの中で描く
            LinearKeyframe(1.0, duration: 0.01)
        }
    }
}

/// チェックの丸の縦横の伸び縮み
private struct CheckScale {
    var x: CGFloat = 1
    var y: CGFloat = 1
}

/// チェックの見た目（テーマの描き方ごと）
private struct CheckMarkFace: View {
    let style: ThemeStyle
    let isCompleted: Bool
    let isAnimated: Bool
    var tilt: Double = 0
    /// タスクごとに決まった種（花火・風船などの色）
    var seed: UInt64 = 0
    /// ろうそくのゆらめきのずれ
    var candlePhase: Double = 0

    @Environment(\.dsAccent) private var accent

    var body: some View {
        switch style {
        case .standard:
            ZStack {
                Circle()
                    .strokeBorder(accent.fill, lineWidth: DS.Stroke.check)
                    .opacity(isCompleted ? 0 : 1)
                Circle()
                    .fill(accent.fill)
                    .opacity(isCompleted ? 1 : 0)
                checkmark
            }
        case .bubble:
            ZStack {
                BubbleSphere(isFilled: isCompleted)
                checkmark
            }
            .animation(DS.Motion.fade, value: isCompleted)
        case .stamp:
            ZStack {
                StampGuide()
                    .opacity(isCompleted ? 0 : 1)
                // 押した瞬間に現れ、そのあと朱色がじわっとにじむ
                StampMark(tilt: tilt, bleed: isCompleted ? 1 : 0)
                    .animation(isAnimated ? .easeOut(duration: DS.Stamp.bleedDuration) : nil, value: isCompleted)
                    .opacity(isCompleted ? 1 : 0)
            }
        case .candle:
            CandleFace(lit: isCompleted ? 0 : 1, isAnimated: isAnimated, phase: candlePhase)
                .animation(isAnimated ? candleAnimation : nil, value: isCompleted)
        case .constellation:
            StarFace(isLit: isCompleted)
                .animation(isAnimated ? .easeOut(duration: 0.2) : nil, value: isCompleted)
        case .water:
            ZStack {
                BubbleSphere(isFilled: false, tint: DS.Water.glass)
                    .opacity(isCompleted ? 0 : 1)
                WaterBead()
                    .opacity(isCompleted ? 1 : 0)
            }
            .animation(isAnimated ? .easeOut(duration: 0.12) : nil, value: isCompleted)
        case .flower(let kind):
            FlowerBlossom(kind: kind, progress: isCompleted ? 1 : 0)
                .animation(isAnimated ? bloomAnimation(kind.spec) : nil, value: isCompleted)
        case .fireworks:
            FireworkCheck(isCompleted: isCompleted, color: FireworkColor.pick(seed: seed), isAnimated: isAnimated)
        case .balloon:
            BalloonCheck(isCompleted: isCompleted, color: BalloonColor.pick(seed: seed), isAnimated: isAnimated)
        case .jelly:
            JellyCheck(isCompleted: isCompleted, flavor: JellyFlavor.pick(seed: seed), isAnimated: isAnimated)
        case .paperPlane:
            PaperPlaneCheck(isCompleted: isCompleted, isAnimated: isAnimated)
        case .shishiOdoshi:
            ShishiCheck(isCompleted: isCompleted, isAnimated: isAnimated)
        case .butterfly:
            ButterflyCheck(isCompleted: isCompleted, palette: ButterflyPalette.pick(seed: seed), isAnimated: isAnimated)
        case .planet:
            PlanetCheck(isCompleted: isCompleted, palette: PlanetPalette.pick(seed: seed), isAnimated: isAnimated)
        case .snowman:
            SnowmanCheck(isCompleted: isCompleted, isAnimated: isAnimated)
        case .weather:
            WeatherCheck(isCompleted: isCompleted, isAnimated: isAnimated)
        }
    }

    /// 消すときは素早く吹き消し、つけ直すときはゆっくり火が育つ
    private var candleAnimation: Animation {
        isCompleted ? .easeIn(duration: DS.Candle.snuffDuration) : .easeOut(duration: DS.Candle.relightDuration)
    }

    /// 咲くときはゆっくり、閉じるときは少し速く
    private func bloomAnimation(_ spec: FlowerSpec) -> Animation {
        isCompleted
            ? .easeOut(duration: spec.bloomDuration).delay(spec.bloomDelay)
            : .easeInOut(duration: spec.closeDuration)
    }

    private var checkmark: some View {
        Image(systemName: "checkmark")
            .font(DS.Typography.iconSmall)
            .foregroundStyle(accent.onFill)
            .opacity(isCompleted ? 1 : 0)
    }
}
