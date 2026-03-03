//
//  AddPetWizardView.swift
//  PatiTakvim
//
//  Created by bilge tunca on 18.12.2025.
//

import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

struct AddPetWizardView: View {
    var onSave: (PetDraft) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var step: Int = 0
    @State private var draft = PetDraft()

    // Photo picker
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var photoPulse: Bool = false

    // ✅ Bu init sayesinde ContentView’de şu şekilde çağırabileceksin:
    // AddPetWizardView { newPet in ... }
    init(_ onSave: @escaping (PetDraft) -> Void) {
        self.onSave = onSave
    }

    var body: some View {
        ZStack {
            NeonBackground().opacity(0.85)

            VStack(spacing: 14) {
                header

                if step == 0 {
                    typeStep
                } else {
                    detailsStep
                }

                footer
            }
            .padding(16)
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        draft.photoData = data
                        photoPulse = true
                    }
                    try? await Task.sleep(nanoseconds: 220_000_000)
                    await MainActor.run { photoPulse = false }
                }
            }
        }
    }

    private var header: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Evcilini ekle")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Text(step == 0 ? "Tür seç" : "Detayları gir")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Text("\(step + 1)/2")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Capsule())
            }
        }
    }

    private var typeStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hangi tür?")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(PetType.allCases) { type in
                    TypeCard(type: type, isSelected: draft.type == type)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
                                draft.type = type
                            }
                            #if canImport(UIKit)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        }
                }
            }
        }
    }

    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Biraz bilgi")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            GlassCard {
                VStack(spacing: 12) {

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        ZStack {
                            #if canImport(UIKit)
                            if let ui = draft.uiImage {
                                Image(uiImage: ui)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Text(draft.type.emoji)
                                    .font(.system(size: 44))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            #else
                            Text(draft.type.emoji)
                                .font(.system(size: 44))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            #endif
                        }
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.22), lineWidth: 2))
                        .shadow(color: .white.opacity(0.12), radius: 14, x: 0, y: 8)
                        .scaleEffect(photoPulse ? 1.06 : 1.0)
                        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: photoPulse)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 6)

                    Text("Fotoğrafa dokunup seçebilirsin")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.65))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 6)

                    TextField("İsim", text: $draft.name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .padding(12)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(.white)

                    TextField("Cins (opsiyonel)", text: $draft.breed)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .padding(12)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button {
                if step == 0 { dismiss() }
                else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        step = 0
                    }
                }
            } label: {
                Text(step == 0 ? "Vazgeç" : "Geri")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Button {
                if step == 0 {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { step = 1 }
                } else {
                    onSave(draft)
                    dismiss()
                }
            } label: {
                Text(step == 0 ? "Devam" : "Kaydet")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(colors: [Color.cyan, Color.pink],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(step == 1 && draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(step == 1 && draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
        }
    }
}

struct TypeCard: View {
    let type: PetType
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text(type.emoji).font(.system(size: 26))
            VStack(alignment: .leading, spacing: 3) {
                Text(type.rawValue)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(isSelected ? "Seçildi" : "Dokun seç")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.cyan)
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected ? Color.cyan.opacity(0.45) : Color.white.opacity(0.10),
                        lineWidth: isSelected ? 1.2 : 1)
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: isSelected)
    }
}
