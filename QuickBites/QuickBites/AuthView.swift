//
//  AuthView.swift
//  QuickBites
//
//  Created by Karakat Tursynbayeva on 9/27/26.
//
import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var languageManager = LanguageManager()
    @State private var isLogin = true

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""

    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isLoading = false

    private var normalizedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var isEmailValid: Bool {
        let parts = normalizedEmail.split(separator: "@")
        return parts.count == 2 && !parts[0].isEmpty && parts[1] == "kbtu.kz"
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.05, blue: 0.10),
                    Color.darkBackground,
                    Color(red: 0.02, green: 0.04, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    HStack {
                        Spacer()
                        Picker("Language", selection: $languageManager.currentLanguage) {
                            ForEach(AppLanguage.allCases) { language in
                                Text(language.rawValue).tag(language)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 150)
                        .background(Color.darkCard)
                        .cornerRadius(8)
                    }
                    .padding(.top, 10)

                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.accentCyan.opacity(0.15))
                                .frame(width: 80, height: 80)

                            Image(systemName: "bolt.fill")
                                .font(.system(size: 38))
                                .foregroundColor(.accentCyan)
                        }

                        Text(languageManager.localizedString("app_title"))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)

                        Text(languageManager.localizedString("app_subtitle"))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 20)

                    VStack(spacing: 16) {
                        if !isLogin {
                            CustomTextField(
                                icon: "person.fill",
                                placeholder: languageManager.localizedString("name_placeholder"),
                                text: $fullName
                            )
                        }

                        CustomTextField(
                            icon: "envelope.fill",
                            placeholder: languageManager.localizedString("email_placeholder"),
                            text: $email
                        )

                        CustomTextField(
                            icon: "lock.fill",
                            placeholder: languageManager.localizedString("password_placeholder"),
                            text: $password,
                            isSecure: true
                        )

                        if !isLogin {
                            CustomTextField(
                                icon: "lock.shield.fill",
                                placeholder: languageManager.localizedString("confirm_password_placeholder"),
                                text: $confirmPassword,
                                isSecure: true
                            )
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }

                        if let successMessage {
                            Text(successMessage)
                                .font(.footnote)
                                .foregroundColor(.green)
                                .multilineTextAlignment(.center)
                        }

                        if isLogin {
                            HStack {
                                Spacer()
                                Text(languageManager.localizedString("forgot_password"))
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 4)

                    Button {
                        Task { await authenticate() }
                    } label: {
                        HStack(spacing: 10) {
                            if isLoading {
                                ProgressView()
                                    .tint(.black)
                            }
                            Text(isLogin
                                 ? languageManager.localizedString("login_button")
                                 : languageManager.localizedString("register_button"))
                                .font(.headline)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.accentCyan)
                        .cornerRadius(16)
                    }
                    .disabled(isLoading)
                    .padding(.top, 10)

                    HStack {
                        Text(isLogin
                             ? languageManager.localizedString("no_account")
                             : languageManager.localizedString("have_account"))
                            .foregroundColor(.gray)
                            .font(.subheadline)

                        Button {
                            withAnimation(.spring()) {
                                errorMessage = nil
                                successMessage = nil
                                isLogin.toggle()
                            }
                        } label: {
                            Text(isLogin
                                 ? languageManager.localizedString("sign_up_link")
                                 : languageManager.localizedString("sign_in_link"))
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.accentCyan)
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
            }
        }
        .preferredColorScheme(.dark)
    }

    @MainActor
    private func authenticate() async {
        errorMessage = nil
        successMessage = nil

        guard isEmailValid else {
            errorMessage = "Please enter a valid @kbtu.kz email address."
            return
        }

        if !isLogin {
            let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)

            guard (2...80).contains(trimmedName.count) else {
                errorMessage = "Your name must contain 2 to 80 characters."
                return
            }

            guard (10...72).contains(password.count) else {
                errorMessage = "Your password must contain 10 to 72 characters."
                return
            }

            guard password == confirmPassword else {
                errorMessage = "Passwords do not match."
                return
            }
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response: AuthResponse

            if isLogin {
                response = try await APIService.shared.login(
                    email: normalizedEmail,
                    password: password
                )
            } else {
                response = try await APIService.shared.register(
                    username: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                    email: normalizedEmail,
                    password: password
                )
            }

            session.finishAuthentication(response)
            if let sessionError = session.errorMessage {
                errorMessage = sessionError
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    AuthView().environmentObject(SessionManager())
}
