//
//  AuthView.swift
//  QuickBites
//
//  Created by Karakat Tursynbayeva on 9/27/26.
//

import SwiftUI

struct AuthView: View {
    @StateObject private var lang = LanguageManager()
    @State private var isLoginState = true
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    
    @State private var errorMessage: String? = nil
    
    private var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.hasSuffix("@kbtu.kz") && trimmed.count > 8
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.03, green: 0.05, blue: 0.10),
                    Color.darkBackground,
                    Color(red: 0.02, green: 0.04, blue: 0.08)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // Переключатель языка
                    HStack {
                        Spacer()
                        Picker("Language", selection: $lang.currentLanguage) {
                            ForEach(AppLanguage.allCases, id: \.self) { language in
                                Text(language.rawValue).tag(language)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 150)
                        .background(Color.darkCard)
                        .cornerRadius(8)
                    }
                    .padding(.top, 10)
                    
                    // Логотип
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.accentCyan.opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 38))
                                .foregroundColor(.accentCyan)
                        }
                        
                        Text(lang.localizedString("app_title"))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(lang.localizedString("app_subtitle"))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 20)
                    
                    // Поля ввода
                    VStack(spacing: 16) {
                        if !isLoginState {
                            CustomTextField(
                                icon: "person.fill",
                                placeholder: lang.localizedString("name_placeholder"),
                                text: $fullName
                            )
                        }
                        
                        CustomTextField(
                            icon: "envelope.fill",
                            placeholder: lang.localizedString("email_placeholder"),
                            text: $email
                        )
                        
                        CustomTextField(
                            icon: "lock.fill",
                            placeholder: lang.localizedString("password_placeholder"),
                            text: $password,
                            isSecure: true
                        )
                        
                        if !isLoginState {
                            CustomTextField(
                                icon: "lock.shield.fill",
                                placeholder: lang.localizedString("confirm_password_placeholder"),
                                text: $confirmPassword,
                                isSecure: true
                            )
                        }
                        
                        // Вывод ошибки если почта не @kbtu.kz
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        
                        if isLoginState {
                            HStack {
                                Spacer()
                                Button(action: {}) {
                                    Text(lang.localizedString("forgot_password"))
                                        .font(.footnote)
                                        .foregroundColor(.accentCyan)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    // Кнопка входа/регистрации
                    Button(action: {
                        errorMessage = nil
                        
                        if !isEmailValid {
                            withAnimation {
                                errorMessage = lang.localizedString("invalid_email_error")
                            }
                            return
                        }
                        
                        if isLoginState {
                            print("Успешный вход: \(email)")
                        } else {
                            print("Успешная регистрация: \(fullName), \(email)")
                        }
                    }) {
                        Text(isLoginState ? lang.localizedString("login_button") : lang.localizedString("register_button"))
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.accentCyan)
                            .cornerRadius(16)
                    }
                    .padding(.top, 10)
                    
                    // Ссылка для смены режима (Вход/Регистрация)
                    HStack {
                        Text(isLoginState ? lang.localizedString("no_account") : lang.localizedString("have_account"))
                            .foregroundColor(.gray)
                            .font(.subheadline)
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                errorMessage = nil
                                isLoginState.toggle()
                            }
                        }) {
                            Text(isLoginState ? lang.localizedString("sign_up_link") : lang.localizedString("sign_in_link"))
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
}

#Preview {
    AuthView()
}
