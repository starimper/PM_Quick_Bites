//
//  ProfileView.swift
//  QuickBites
//
//  Created by Karakat Tursynbayeva on 11/5/26.
//
import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject private var session: SessionManager
    @EnvironmentObject private var settings: AppSettings

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?

    @State private var orders: [QuickOrder] = []
    @State private var isLoadingOrders = false
    @State private var showSignOutConfirmation = false
    @State private var showPhotoError = false

    private var userId: String {
        session.user?.id.uuidString ?? "unknown"
    }

    private var avatarURL: URL {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        .appendingPathComponent("avatar-\(userId).jpg")
    }

    private var totalOrders: Int {
        orders.count
    }

    private var completedOrders: Int {
        orders.filter { $0.status == "COMPLETED" }.count
    }

    private var activeOrders: Int {
        orders.filter {
            !["COMPLETED", "CANCELLED"].contains($0.status)
        }.count
    }

    private var roleTitle: String {
        switch session.user?.role {
        case "STUDENT":
            return settings.text("student")
        case "BUFFET_STAFF":
            return settings.text("staff")
        case "CAMPUS_ADMIN":
            return settings.text("admin")
        default:
            return "User"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection

                        if session.user?.role == "STUDENT" {
                            statisticsSection
                        }

                        preferencesSection
                        accountSection
                        securitySection
                        aboutSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 36)
                }
            }
            .navigationTitle(settings.text("profile"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.darkBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task(id: userId) {
                loadSavedPhoto()

                if session.user?.role == "STUDENT" {
                    await loadOrders()
                }
            }
            .onChange(of: selectedPhoto) { newPhoto in
                Task {
                    await updateProfilePhoto(newPhoto)
                }
            }
            .confirmationDialog(
                settings.text("sign_out_message"),
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    settings.text("sign_out"),
                    role: .destructive
                ) {
                    session.signOut()
                }

                Button(
                    settings.text("cancel"),
                    role: .cancel
                ) {}
            }
            .alert(
                settings.text("photo_error"),
                isPresented: $showPhotoError
            ) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 14) {
            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images
            ) {
                ZStack(alignment: .bottomTrailing) {
                    avatarView

                    Image(systemName: "camera.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 34, height: 34)
                        .background(Color.accentCyan)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Color.darkBackground, lineWidth: 3)
                        }
                }
            }
            .buttonStyle(.plain)

            Text(session.user?.username ?? "User")
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(.white)

            Text(session.user?.email ?? "")
                .font(.subheadline)
                .foregroundStyle(.gray)

            Text(roleTitle)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.accentCyan)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.accentCyan.opacity(0.12))
                .clipShape(Capsule())

            HStack(spacing: 16) {
                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images
                ) {
                    Label(
                        settings.text("change_photo"),
                        systemImage: "photo"
                    )
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.accentCyan)
                }

                if profileImage != nil {
                    Button {
                        removeProfilePhoto()
                    } label: {
                        Label(
                            settings.text("remove_photo"),
                            systemImage: "trash"
                        )
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(Color.darkCard)
                .frame(width: 112, height: 112)

            if let profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 106, height: 106)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .foregroundStyle(Color.accentCyan.opacity(0.85))
            }
        }
        .overlay {
            Circle()
                .stroke(
                    Color.accentCyan.opacity(0.5),
                    lineWidth: 2
                )
        }
    }

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(settings.text("orders"))

            HStack(spacing: 10) {
                statisticCard(
                    value: totalOrders,
                    title: settings.text("total_orders"),
                    icon: "bag.fill"
                )

                statisticCard(
                    value: completedOrders,
                    title: settings.text("completed"),
                    icon: "checkmark.circle.fill"
                )

                statisticCard(
                    value: activeOrders,
                    title: settings.text("active_orders"),
                    icon: "clock.fill"
                )
            }

            if isLoadingOrders {
                ProgressView()
                    .tint(Color.accentCyan)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func statisticCard(
        value: Int,
        title: String,
        icon: String
    ) -> some View {
        VStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.accentCyan)

            Text("\(value)")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)

            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 110)
        .background(Color.darkCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(settings.text("preferences"))

            HStack(spacing: 14) {
                settingIcon("globe")

                Text(settings.text("language"))
                    .foregroundStyle(.white)

                Spacer()

                Picker(
                    settings.text("language"),
                    selection: $settings.language
                ) {
                    ForEach(AppLocale.allCases) { language in
                        Text(language.title)
                            .tag(language)
                    }
                }
                .tint(Color.accentCyan)
            }
            .padding(16)
            .background(Color.darkCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(settings.text("account_info"))

            VStack(spacing: 0) {
                informationRow(
                    icon: "person.fill",
                    title: settings.text("my_account"),
                    value: session.user?.username ?? "-"
                )

                Divider()
                    .overlay(Color.darkCardBorder)
                    .padding(.leading, 52)

                informationRow(
                    icon: "envelope.fill",
                    title: settings.text("email"),
                    value: session.user?.email ?? "-"
                )

                Divider()
                    .overlay(Color.darkCardBorder)
                    .padding(.leading, 52)

                informationRow(
                    icon: "person.text.rectangle.fill",
                    title: settings.text("role"),
                    value: roleTitle
                )
            }
            .background(Color.darkCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(settings.text("security"))

            Button {
                showSignOutConfirmation = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 18))
                        .frame(width: 28)

                    Text(settings.text("sign_out"))
                        .fontWeight(.medium)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                }
                .foregroundStyle(.red)
                .padding(18)
                .background(Color.darkCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var aboutSection: some View {
        VStack(spacing: 8) {
            Text("QuickBites")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.accentCyan)

            Text(settings.text("about"))
                .font(.caption)
                .foregroundStyle(.gray)

            Text("\(settings.text("version")) 1.0")
                .font(.caption2)
                .foregroundStyle(.gray.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
    }

    private func settingIcon(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 17))
            .foregroundStyle(Color.accentCyan)
            .frame(width: 28)
    }

    private func informationRow(
        icon: String,
        title: String,
        value: String
    ) -> some View {
        HStack(spacing: 14) {
            settingIcon(icon)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.gray)

                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
    }

    @MainActor
    private func loadOrders() async {
        isLoadingOrders = true
        defer { isLoadingOrders = false }

        do {
            orders = try await APIService.shared.myOrders()
        } catch {
            orders = []
            print("Unable to load order statistics: \(error)")
        }
    }

    private func loadSavedPhoto() {
        guard let data = try? Data(contentsOf: avatarURL),
              let image = UIImage(data: data) else {
            profileImage = nil
            return
        }

        profileImage = image
    }

    @MainActor
    private func updateProfilePhoto(
        _ item: PhotosPickerItem?
    ) async {
        guard let item else { return }

        do {
            guard let data = try await item.loadTransferable(
                type: Data.self
            ),
            let image = UIImage(data: data),
            let jpegData = image.jpegData(
                compressionQuality: 0.75
            ) else {
                showPhotoError = true
                return
            }

            try jpegData.write(
                to: avatarURL,
                options: .atomic
            )

            profileImage = image
        } catch {
            showPhotoError = true
        }
    }

    private func removeProfilePhoto() {
        try? FileManager.default.removeItem(at: avatarURL)
        profileImage = nil
        selectedPhoto = nil
    }
}
