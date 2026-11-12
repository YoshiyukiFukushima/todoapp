//
//  AnimatedCheckboxButton.swift
//  todoapp
//

import SwiftUI

struct AnimatedCheckboxButton: View {
    let isCompleted: Bool
    let animationsEnabled: Bool
    let emojiEffectEnabled: Bool
    let action: () -> Void

    @Environment(\.dsAccent) private var accent
    @State private var bounce = false
    @State private var flashOpacity: Double = 0
    @State private var particles: [EmojiParticle] = []
    @State private var showSplash = false

    var body: some View {
        Button(action: handleTap) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(DS.Typography.icon)
                .foregroundStyle(isCompleted ? accent.fill : DS.Colors.textTertiary)
                .scaleEffect(bounce ? 1.2 : 1.0)
                .background(
                    Circle()
                        .fill(accent.soft)
                        .opacity(flashOpacity)
                )
        }
        .buttonStyle(.plain)
        .overlay {
            if showSplash {
                EmojiSplashView(particles: particles)
            }
        }
    }

    // 完了時の演出はフェーズ4で絵文字エフェクトごと作り直す（docs/design.md）
    private func handleTap() {
        let willComplete = !isCompleted
        action()

        guard willComplete, animationsEnabled else { return }

        flashOpacity = 1
        withAnimation(.easeOut(duration: 0.2)) { flashOpacity = 0 }

        withAnimation(.easeOut(duration: 0.1)) { bounce = true }
        withAnimation(.easeOut(duration: 0.1).delay(0.1)) { bounce = false }

        guard emojiEffectEnabled else { return }

        particles = EmojiSplashView.makeParticles()
        showSplash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showSplash = false
        }
    }
}
