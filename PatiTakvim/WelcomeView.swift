//
//  WelcomeView.swift
//  PatiTakvim
//
//  Created by bilge tunca on 18.12.2025.
//

import SwiftUI

struct WelcomeView: View {
    var onStart: () -> Void
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            VStack(spacing: 10) {
                Text("🐾")
                    .font(.system(size: 64))
                    .scaleEffect(pulse ? 1.05 : 0.95)
                    .shadow(color: .purple.opacity(0.4), radius: 18)

                Text("PatiTakvim")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("Bakımları unutma. Evcilini mutlu et.")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
            }

            Spacer()

            Button(action: onStart) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                    Text("Başlayalım")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.black)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(colors: [Color.cyan, Color.pink],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .cyan.opacity(0.35), radius: 16, x: 0, y: 10)
            }
            .padding(.horizontal, 26)

            Spacer().frame(height: 26)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
