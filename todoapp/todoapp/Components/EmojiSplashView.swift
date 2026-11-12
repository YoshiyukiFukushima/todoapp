//
//  EmojiSplashView.swift
//  todoapp
//

import SwiftUI

struct EmojiParticle: Identifiable {
    let id = UUID()
    let emoji: String
    let angle: Double
    let velocity: Double
}

struct EmojiSplashView: View {
    static let emojiSet = ["🎉", "✨", "🌟", "⭐", "🎊"]

    static func makeParticles() -> [EmojiParticle] {
        let count = Int.random(in: 8...12)
        return (0..<count).map { i in
            EmojiParticle(
                emoji: emojiSet.randomElement()!,
                angle: Double(i) * (2 * .pi / Double(count)),
                velocity: Double.random(in: 200...400)
            )
        }
    }

    let particles: [EmojiParticle]

    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Text(particle.emoji)
                    .font(DS.Typography.body)
                    .scaleEffect(animate ? 0.3 : 1.0)
                    .opacity(animate ? 0.0 : 1.0)
                    .offset(
                        x: animate ? cos(particle.angle) * particle.velocity * 0.2 : 0,
                        y: animate ? sin(particle.angle) * particle.velocity * 0.2 : 0
                    )
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.2)) {
                animate = true
            }
        }
    }
}
