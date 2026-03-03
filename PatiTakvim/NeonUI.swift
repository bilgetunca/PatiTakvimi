//
//  NeonUI.swift
//  PatiTakvim
//
//  Created by bilge tunca on 18.12.2025.
//

import SwiftUI

struct NeonBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color.indigo.opacity(0.35), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(LinearGradient(colors: [Color.purple.opacity(0.75), Color.clear],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 320, height: 320)
                .blur(radius: 18)
                .offset(x: animate ? -120 : -30, y: animate ? -220 : -140)

            Circle()
                .fill(LinearGradient(colors: [Color.cyan.opacity(0.70), Color.clear],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 360, height: 360)
                .blur(radius: 18)
                .offset(x: animate ? 140 : 60, y: animate ? 240 : 160)

            Circle()
                .fill(LinearGradient(colors: [Color.orange.opacity(0.65), Color.clear],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 260, height: 260)
                .blur(radius: 18)
                .offset(x: animate ? 120 : 10, y: animate ? -40 : -90)
            Circle()
                .fill(LinearGradient(colors: [Color.pink.opacity(0.65), Color.clear],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 300, height: 300)
                .blur(radius: 18)
                .offset(x: animate ? -160 : -40, y: animate ? 120 : 220)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct GlassCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(18)
            .background(
                ZStack {
                    // Cam efekti
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.ultraThinMaterial)

                    // Okunabilirlik için koyu katman
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.black.opacity(0.32))
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
    }
}

// MARK: - Bottom Dock Panel

struct GlassDock<Content: View>: View {
    let height: CGFloat
    let content: Content

    init(height: CGFloat, @ViewBuilder content: () -> Content) {
        self.height = height
        self.content = content()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.black.opacity(0.20))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 10)

            content
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
        }
        .frame(height: height)
    }
}
