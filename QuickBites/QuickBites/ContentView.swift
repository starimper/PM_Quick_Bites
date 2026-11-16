//
//  ContentView.swift
//  QuickBites
//
//  Created by Karakat Tursynbayeva on 9/27/26.
//
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        Group {
            if session.isAuthenticated {
                switch session.user?.role {
                case "BUFFET_STAFF":
                    StaffDashboardView()

                case "CAMPUS_ADMIN":
                    AdminDashboardView()

                default:
                    StudentTabsView()
                }
            } else {
                AuthView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct StudentTabsView: View {
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var cart = CartStore()

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label(
                        settings.text("home"),
                        systemImage: "house.fill"
                    )
                }

            CartView()
                .tabItem {
                    Label(
                        settings.text("cart"),
                        systemImage: "cart.fill"
                    )
                }
                .badge(cart.count)

            OrdersView()
                .tabItem {
                    Label(
                        settings.text("orders"),
                        systemImage: "receipt.fill"
                    )
                }

            NotificationsView()
                .tabItem {
                    Label(
                        settings.text("alerts"),
                        systemImage: "bell.fill"
                    )
                }

            ProfileView()
                .tabItem {
                    Label(
                        settings.text("profile"),
                        systemImage: "person.crop.circle.fill"
                    )
                }
        }
        .environmentObject(cart)
        .tint(.accentCyan)
    }
}
