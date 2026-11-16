//
//  MenuView.swift
//  QuickBites
//
//  Created by Karakat Tursynbayeva on 11/5/26.
//

import SwiftUI

struct MenuView: View {
    let buffet: Buffet
    @EnvironmentObject private var cart: CartStore
    @State private var menu: BuffetMenu?
    @State private var error: String?
    @State private var loading = false
    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Label(buffet.location, systemImage: "mappin").foregroundStyle(.gray)
                    Text("Today's Menu").font(.title2.bold()).foregroundStyle(.white)
                    if loading { ProgressView("Loading menu...") }
                    if let error { Text(error).foregroundStyle(.red); Button("Retry") { Task { await load() } } }
                    if !loading && error == nil && menu?.meals.isEmpty == true { EmptyStateView(message: "No meals available for today", symbol: "tray") }
                    ForEach(menu?.meals ?? []) { meal in
                        HStack(alignment: .top, spacing: 14) {
                            MealImageView(url: meal.photoUrl)
                            VStack(alignment: .leading, spacing: 7) {
                                Text(meal.name).font(.headline).foregroundStyle(.white)
                                if let description = meal.description { Text(description).font(.caption).foregroundStyle(.gray).lineLimit(3) }
                                Text(PriceFormat.tenge(meal.price)).fontWeight(.bold).foregroundStyle(Color.accentCyan)
                                Text(meal.available ? "Available" : "Sold out").font(.caption).foregroundStyle(meal.available ? .green : .red)
                                HStack {
                                    if cart.quantity(for: meal) > 0 {
                                        Button { cart.remove(meal) } label: { Image(systemName: "minus.circle.fill") }
                                        Text("\(cart.quantity(for: meal))").foregroundStyle(.white)
                                    }
                                    Button { cart.add(meal, from: buffet) } label: { Image(systemName: "plus.circle.fill") }
                                        .disabled(!meal.available || cart.quantity(for: meal) >= 20)
                                }.font(.title2).tint(Color.accentCyan)
                            }
                            Spacer(minLength: 0)
                        }.padding(14).background(Color.darkCard, in: RoundedRectangle(cornerRadius: 16))
                    }
                }.padding(20)
            }.refreshable { await load() }
        }
        .navigationTitle(buffet.name)
        .task { await load() }
    }
    @MainActor private func load() async {
        loading = true; error = nil
        defer { loading = false }
        do { menu = try await APIService.shared.getMenu(buffetId: buffet.id) } catch { self.error = error.localizedDescription }
    }
}

struct MealImageView: View {
    let url: String?
    var body: some View {
        Group {
            if let url, let remote = URL(string: url), ["http", "https"].contains(remote.scheme?.lowercased() ?? "") {
                AsyncImage(url: remote) { image in image.resizable().scaledToFill() } placeholder: { Image(systemName: "fork.knife").foregroundStyle(Color.accentCyan) }
            } else { Image(systemName: "fork.knife").foregroundStyle(Color.accentCyan) }
        }
        .frame(width: 76, height: 76).background(Color.darkCardBorder)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
