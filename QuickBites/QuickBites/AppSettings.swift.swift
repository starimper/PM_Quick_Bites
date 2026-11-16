//
//  AppSettings.swift.swift
//  QuickBites
//
//  Created by Karakat Tursynbayeva on 11/5/26.
//

import Foundation
import SwiftUI
import Combine

enum AppLocale: String, CaseIterable, Identifiable {
    case english = "en"
    case russian = "ru"
    case kazakh = "kk"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .english: return "English"
        case .russian: return "Русский"
        case .kazakh: return "Қазақша"
        }
    }

    var shortTitle: String {
        switch self {
        case .english: return "EN"
        case .russian: return "RU"
        case .kazakh: return "KZ"
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("quickbites.language")
    private var storedLanguage = AppLocale.english.rawValue

    @Published var language: AppLocale = .english {
        didSet {
            storedLanguage = language.rawValue
        }
    }

    init() {
        language = AppLocale(rawValue: storedLanguage) ?? .english
    }

    func text(_ key: String) -> String {
        let translations: [String: [String: String]] = [
            "profile": [
                "en": "Profile",
                "ru": "Профиль",
                "kk": "Профиль"
            ],
            "home": [
                "en": "Home",
                "ru": "Главная",
                "kk": "Басты бет"
            ],
            "cart": [
                "en": "Cart",
                "ru": "Корзина",
                "kk": "Себет"
            ],
            "orders": [
                "en": "Orders",
                "ru": "Заказы",
                "kk": "Тапсырыстар"
            ],
            "alerts": [
                "en": "Alerts",
                "ru": "Уведомления",
                "kk": "Хабарламалар"
            ],
            "my_account": [
                "en": "My Account",
                "ru": "Мой аккаунт",
                "kk": "Менің аккаунтым"
            ],
            "student": [
                "en": "Student",
                "ru": "Студент",
                "kk": "Студент"
            ],
            "staff": [
                "en": "Buffet Staff",
                "ru": "Сотрудник буфета",
                "kk": "Буфет қызметкері"
            ],
            "admin": [
                "en": "Campus Admin",
                "ru": "Администратор",
                "kk": "Әкімші"
            ],
            "total_orders": [
                "en": "Total Orders",
                "ru": "Всего заказов",
                "kk": "Барлық тапсырыс"
            ],
            "completed": [
                "en": "Completed",
                "ru": "Завершено",
                "kk": "Аяқталды"
            ],
            "active_orders": [
                "en": "Active",
                "ru": "Активные",
                "kk": "Белсенді"
            ],
            "preferences": [
                "en": "Preferences",
                "ru": "Настройки",
                "kk": "Баптаулар"
            ],
            "language": [
                "en": "App Language",
                "ru": "Язык приложения",
                "kk": "Қолданба тілі"
            ],
            "account_info": [
                "en": "Account Information",
                "ru": "Информация об аккаунте",
                "kk": "Аккаунт ақпараты"
            ],
            "email": [
                "en": "Email Address",
                "ru": "Электронная почта",
                "kk": "Электрондық пошта"
            ],
            "role": [
                "en": "Account Role",
                "ru": "Роль аккаунта",
                "kk": "Аккаунт рөлі"
            ],
            "security": [
                "en": "Security",
                "ru": "Безопасность",
                "kk": "Қауіпсіздік"
            ],
            "sign_out": [
                "en": "Sign Out",
                "ru": "Выйти",
                "kk": "Шығу"
            ],
            "sign_out_message": [
                "en": "Are you sure you want to sign out?",
                "ru": "Вы уверены, что хотите выйти?",
                "kk": "Аккаунттан шығуға сенімдісіз бе?"
            ],
            "cancel": [
                "en": "Cancel",
                "ru": "Отмена",
                "kk": "Бас тарту"
            ],
            "change_photo": [
                "en": "Change Photo",
                "ru": "Изменить фото",
                "kk": "Фотоны өзгерту"
            ],
            "remove_photo": [
                "en": "Remove Photo",
                "ru": "Удалить фото",
                "kk": "Фотоны өшіру"
            ],
            "about": [
                "en": "About QuickBites",
                "ru": "О QuickBites",
                "kk": "QuickBites туралы"
            ],
            "version": [
                "en": "Version",
                "ru": "Версия",
                "kk": "Нұсқа"
            ],
            "photo_error": [
                "en": "Unable to load the selected photo.",
                "ru": "Не удалось загрузить фотографию.",
                "kk": "Фотосуретті жүктеу мүмкін болмады."
            ]
        ]

        return translations[key]?[language.rawValue]
            ?? translations[key]?["en"]
            ?? key
    }
}
