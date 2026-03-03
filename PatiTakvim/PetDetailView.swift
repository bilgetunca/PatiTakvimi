import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import QuickLook

struct PetDetailView: View {
    @Binding var pet: PetDraft
    var onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    // Profil foto
    @State private var profilePhotoItem: PhotosPickerItem? = nil
    @State private var isLoadingProfilePhoto = false
    @State private var previewURL: URL? = nil
    @State private var showPreview = false

    // Yaş modu
    @State private var knowsBirthDate: Bool = true
    @State private var ageYearsText: String = ""
    @State private var ageMonthsText: String = ""

    // Kilo
    @State private var weightText: String = ""

    // Belge ekleme
    @State private var showFileImporter = false
    @State private var docPhotoItem: PhotosPickerItem? = nil
    @State private var showAddDocSheet = false

    // Belge formu
    @State private var newDocType: PetDocumentType = .vaccineCard
    @State private var newDocTitle: String = ""
    @State private var pendingDocData: Data? = nil
    @State private var pendingDocFileName: String = ""

    private static let trShortDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMM"
        return f
    }()

    private static let trShortDateTime: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMM yyyy HH:mm"
        return f
    }()

    var body: some View {
        ZStack {
            NeonBackground()

            ScrollView {
                VStack(spacing: 14) {
                    profileHeader
                    basicInfoCard
                    statsCard
                    documentsCard
                    deleteButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle(pet.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear { hydrateFromPet() }
        .onChange(of: profilePhotoItem) { _, newItem in
            guard let newItem else { return }
            Task { await loadProfilePhoto(from: newItem) }
        }
        .onChange(of: docPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task { await loadDocumentImage(from: newItem) }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf, .image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                importFile(url: url)
            case .failure:
                break
            }
        }
        .sheet(isPresented: $showAddDocSheet) {
            addDocumentSheet
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showPreview) {
            if let previewURL {
                QuickLookPreview(url: previewURL)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - UI

    private var profileHeader: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    if let ui = pet.uiImage {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Text(pet.type.emoji)
                            .font(.system(size: 44))
                    }
                }
                .frame(width: 86, height: 86)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.20), lineWidth: 1.5))
                .shadow(color: .white.opacity(0.10), radius: 12, x: 0, y: 8)

                VStack(alignment: .leading, spacing: 8) {
                    Text(pet.displayName)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Text("\(pet.type.emoji) \(pet.type.rawValue)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))

                    PhotosPicker(selection: $profilePhotoItem, matching: .images) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text(pet.photoData == nil ? "Fotoğraf ekle" : "Fotoğrafı değiştir")
                        }
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.10))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1))
                    }
                    .disabled(isLoadingProfilePhoto)
                    .opacity(isLoadingProfilePhoto ? 0.6 : 1.0)

                    if isLoadingProfilePhoto {
                        Text("Yükleniyor…")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                }

                Spacer()
            }
        }
    }

    private var basicInfoCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Temel Bilgiler")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                HStack(spacing: 12) {
                    Text("Tür")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))

                    Spacer()

                    Picker("", selection: $pet.type) {
                        ForEach(PetType.allCases) { t in
                            Text("\(t.emoji) \(t.rawValue)").tag(t)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                }

                field(title: "İsim", text: $pet.name, placeholder: "Örn: Misket")
                field(title: "Cins", text: $pet.breed, placeholder: "Örn: British Shorthair")
            }
        }
    }

    private var statsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Profil Detayları")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Toggle(isOn: $knowsBirthDate) {
                    Text("Doğum tarihini biliyorum")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .tint(.white.opacity(0.85))
                .onChange(of: knowsBirthDate) { _, newValue in
                    if newValue {
                        // manuel yaş temizle
                        pet.approxAgeYears = nil
                        pet.approxAgeMonths = nil
                        ageYearsText = ""
                        ageMonthsText = ""
                        // birthDate boşsa default verelim
                        if pet.birthDate == nil {
                            pet.birthDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())
                        }
                    } else {
                        // doğum tarihini kaldır
                        pet.birthDate = nil
                    }
                }

                if knowsBirthDate {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Doğum tarihi")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))

                        DatePicker(
                            "",
                            selection: Binding(
                                get: { pet.birthDate ?? Calendar.current.date(byAdding: .year, value: -1, to: Date())! },
                                set: { pet.birthDate = $0 }
                            ),
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                        .tint(.white)
                        .labelsHidden()

                        Text("Yaş: \(pet.ageText)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Yaklaşık yaş")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))

                        HStack(spacing: 12) {
                            TextField("Yıl", text: $ageYearsText)
                                .keyboardType(.numberPad)
                                .padding(12)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 1))
                                .foregroundStyle(.white)

                            TextField("Ay", text: $ageMonthsText)
                                .keyboardType(.numberPad)
                                .padding(12)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 1))
                                .foregroundStyle(.white)

                            Button {
                                saveApproxAge()
                            } label: {
                                Text("Kaydet")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                    .background(Color.white.opacity(0.10))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1))
                            }
                            .foregroundStyle(.white)
                        }

                        Text("Yaş: \(pet.ageText)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }

                Divider().background(Color.white.opacity(0.15))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Kilo (kg)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))

                    TextField("Örn: 4,8", text: $weightText)
                        .keyboardType(.decimalPad)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )

                    Button {
                        saveWeight()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Kiloyu kaydet")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.10))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1))
                    }

                    if let w = pet.weightKg {
                        Text("Son kayıt: \(String(format: "%.1f", w)) kg")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                    } else {
                        Text("Henüz kilo kaydı yok")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                }
            }
        }
    }

    private var documentsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Belgeler")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                }

                // ✅ MENÜYÜ SÖKTÜM. Çünkü menü içinde PhotosPicker düzgün tetiklenmiyor.
                HStack(spacing: 10) {
                    PhotosPicker(selection: $docPhotoItem, matching: .images) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo")
                            Text("Fotoğraf ekle")
                        }
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.10))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1))
                    }

                    Button {
                        showFileImporter = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "doc")
                            Text("PDF/Dosya ekle")
                        }
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.10))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1))
                    }
                }

                if pet.documents.isEmpty {
                    Text("Henüz belge eklenmedi.")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.70))
                } else {
                    VStack(spacing: 10) {
                        ForEach(pet.documents) { doc in
                            HStack(spacing: 12) {
                                Image(systemName: doc.type.icon)
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Color.white.opacity(0.10))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(doc.title)
                                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                                        .foregroundStyle(.white)

                                    Text("\(doc.type.rawValue) • \(smallDate(doc.createdAt))")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.7))
                                        .lineLimit(1)
                                }

                                Spacer()

                                Button(role: .destructive) {
                                    pet.documents.removeAll { $0.id == doc.id }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let url = writeTempFile(for: doc) {
                                    previewURL = url
                                    showPreview = true
                                }
                            }
                        }
                    }
                }

                Text("Not: Çok büyük PDF’ler ekleme. Şimdilik uygulama içinde saklıyoruz.")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            onDelete()
            dismiss()
        } label: {
            HStack {
                Image(systemName: "trash.fill")
                Text("Bu evcili sil")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red.opacity(0.20))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.red.opacity(0.35), lineWidth: 1)
            )
            .foregroundStyle(.white)
        }
        .padding(.top, 6)
    }

    // MARK: - Add Document Sheet

    private var addDocumentSheet: some View {
        ZStack {
            NeonBackground()
            VStack(spacing: 14) {
                Text("Yeni Belge")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Belge türü")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))

                        Picker("", selection: $newDocType) {
                            ForEach(PetDocumentType.allCases) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.white)

                        field(title: "Başlık", text: $newDocTitle, placeholder: "Örn: Voody Pasaportu")

                        if pendingDocData == nil {
                            Text("Önce bir dosya/foto seç.")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.65))
                        } else {
                            Text("Seçilen: \(pendingDocFileName)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.75))
                                .lineLimit(1)
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        showAddDocSheet = false
                        pendingDocData = nil
                        pendingDocFileName = ""
                    } label: {
                        Text("Vazgeç")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    Button {
                        commitDocument()
                    } label: {
                        Text("Kaydet")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [Color.cyan, Color.pink],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(.black)
                    }
                    .disabled(pendingDocData == nil || newDocTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity((pendingDocData == nil || newDocTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.6 : 1.0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Helpers

    private func hydrateFromPet() {
        knowsBirthDate = (pet.birthDate != nil)
        ageYearsText = pet.approxAgeYears.map(String.init) ?? ""
        ageMonthsText = pet.approxAgeMonths.map(String.init) ?? ""

        if let w = pet.weightKg {
            weightText = String(format: "%.1f", w).replacingOccurrences(of: ".", with: ",")
        } else {
            weightText = ""
        }
    }

    private func trimmed(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func stagePendingDocument(data: Data, fileName: String) {
        pendingDocData = data
        pendingDocFileName = fileName
        newDocTitle = newDocTitle.isEmpty ? "\(pet.displayName) Belgesi" : newDocTitle
        newDocType = .vaccineCard
        showAddDocSheet = true
    }

    private func field(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))

            TextField(placeholder, text: text)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        }
    }

    private func writeTempFile(for doc: PetDocument) -> URL? {
        let ext = fileExtension(from: doc.fileName)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pet_doc_\(doc.id.uuidString)")
            .appendingPathExtension(ext)

        do {
            try doc.data.write(to: url, options: [.atomic])
            return url
        } catch {
            return nil
        }
    }

    private func fileExtension(from fileName: String) -> String {
        let ext = URL(fileURLWithPath: fileName).pathExtension.lowercased()
        if ext.isEmpty { return "pdf" }
        return ext
    }

    private func loadProfilePhoto(from item: PhotosPickerItem) async {
        isLoadingProfilePhoto = true
        defer { isLoadingProfilePhoto = false }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                await MainActor.run { pet.photoData = data }
            }
        } catch { }
    }

    private func loadDocumentImage(from item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    stagePendingDocument(data: data, fileName: "photo.jpg")
                }
            }
        } catch { }
    }

    private func importFile(url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer { if canAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            stagePendingDocument(data: data, fileName: url.lastPathComponent)
        } catch { }
    }

    private func commitDocument() {
        guard let data = pendingDocData else { return }
        let title = trimmed(newDocTitle)
        guard !title.isEmpty else { return }

        let fileName = pendingDocFileName.isEmpty ? "document" : pendingDocFileName

        let doc = PetDocument(
            type: newDocType,
            title: title,
            fileName: fileName,
            data: data
        )
        pet.documents.insert(doc, at: 0)

        pendingDocData = nil
        pendingDocFileName = ""
        newDocTitle = ""
        showAddDocSheet = false
    }

    private func saveWeight() {
        let normalized = trimmed(weightText).replacingOccurrences(of: ",", with: ".")

        guard let value = Double(normalized), value > 0, value < 200 else { return }
        pet.weightKg = value
        pet.weightUpdatedAt = Date()
    }

    private func saveApproxAge() {
        let y = Int(trimmed(ageYearsText))
        let m = Int(trimmed(ageMonthsText))

        // Ay 0-11 arası mantıklı
        let mm = max(0, min(11, m ?? 0))
        let yy = max(0, y ?? 0)

        pet.approxAgeYears = (yy == 0 && mm == 0) ? nil : yy
        pet.approxAgeMonths = (yy == 0 && mm == 0) ? nil : mm
    }

    private func smallDate(_ date: Date) -> String {
        Self.trShortDate.string(from: date)
    }
}

struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(url: URL) { self.url = url }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }
}
