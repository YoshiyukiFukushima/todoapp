//
//  ProgressRing.swift
//  todoapp
//
//  進み具合の輪。全部終わると緑になる。
//

import SwiftUI

struct ProgressRing: View {
    let done: Int
    let total: Int

    @Environment(\.dsAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var fraction: Double {
        total == 0 ? 0 : Double(done) / Double(total)
    }

    private var isComplete: Bool { total > 0 && done == total }

    var body: some View {
        ZStack {
            Circle()
                .stroke(DS.Colors.surfaceSunken, lineWidth: DS.Size.ringLineWidth)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(isComplete ? DS.Colors.success : accent.fill,
                        style: StrokeStyle(lineWidth: DS.Size.ringLineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if isComplete {
                Image(systemName: "checkmark")
                    .font(DS.Typography.iconSmall)
                    .foregroundStyle(DS.Colors.success)
            }
        }
        .frame(width: DS.Size.ring, height: DS.Size.ring)
        .animation(DS.Motion.respecting(reduceMotion), value: fraction)
        .accessibilityHidden(true)
    }
}
