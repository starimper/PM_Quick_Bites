//
//  LanguageManager.swift
//  QuickBites
//
//  Created by Karakat Tursynbayeva on 9/27/26.
//

import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable, Identifiable {
    case ru = "RU"
    case kk = "KZ"
    case en = "EN"
    
    var id: String { self.rawValue }
}

class LanguageManager: ObservableObject {
    @Published var currentLanguage: AppLanguage = .ru
    
    func localizedString(_ key: String) -> String {
        switch currentLanguage {
        case .ru: return localizedRU[key] ?? key
        case .kk: return localizedKK[key] ?? key
        case .en: return localizedEN[key] ?? key
        }
    }
    
    private let localizedRU: [String: String] = [
        "app_title": "QuickBite",
        "app_subtitle": "Быстрый перекус на перемене",
        "login": "Войти",
        "register": "Регистрация",
        "email_placeholder": "Почта (...@kbtu.kz)",
        "password_placeholder": "Пароль",
        "confirm_password_placeholder": "Повторите пароль",
        "name_placeholder": "Имя и Фамилия",
        "forgot_password": "Забыли пароль?",
        "no_account": "Еще нет аккаунта?",
        "have_account": "Уже есть аккаунт?",
        "sign_up_link": "Зарегистрироваться",
        "sign_in_link": "Войти",
        "login_button": "Войти в профиль",
        "register_button": "Создать аккаунт",
        "invalid_email_error": "Почта должна заканчиваться на @kbtu.kz"
    ]
    
    private let localizedKK: [String: String] = [
        "app_title": "QuickBite",
        "app_subtitle": "Үзілістегі жылдам тамақтану",
        "login": "Кіру",
        "register": "Тіркелу",
        "email_placeholder": "Пошта (...@kbtu.kz)",
        "password_placeholder": "Құпия сөз",
        "confirm_password_placeholder": "Құпия сөзді қайталаңыз",
        "name_placeholder": "Аты-жөні",
        "forgot_password": "Құпия сөзді ұмыттыңыз ба?",
        "no_account": "Тіркелмегенсіз бе?",
        "have_account": "Тіркелгенсіз бе?",
        "sign_up_link": "Тіркелу",
        "sign_in_link": "Кіру",
        "login_button": "Профильге кіру",
        "register_button": "Аккаунт ашу",
        "invalid_email_error": "Пошта @kbtu.kz аяқталуы тиіс"
    ]
    
    private let localizedEN: [String: String] = [
        "app_title": "QuickBite",
        "app_subtitle": "Quick snacks between classes",
        "login": "Sign In",
        "register": "Sign Up",
        "email_placeholder": "Email (...@kbtu.kz)",
        "password_placeholder": "Password",
        "confirm_password_placeholder": "Confirm password",
        "name_placeholder": "Full Name",
        "forgot_password": "Forgot password?",
        "no_account": "Don't have an account?",
        "have_account": "Already have an account?",
        "sign_up_link": "Register",
        "sign_in_link": "Sign In",
        "login_button": "Sign In",
        "register_button": "Create Account",
        "invalid_email_error": "Email must end with @kbtu.kz"
    ]
}
