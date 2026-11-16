//
//  QuickBitesApp.swift
//  QuickBites
//
//  Created by Karakat Tursynbayeva on 9/27/26.
//

import SwiftUI

@main
struct QuickBitesApp: App {
    @StateObject private var session = SessionManager()
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
                .environmentObject(settings)
                .environment(
                    \.locale,
                    Locale(identifier: settings.language.rawValue)
                )
                .preferredColorScheme(.dark)
        }
    }
}
