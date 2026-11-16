//
//  HomeView.swift
//  QuickBites
//
//  Created by Karakat Tursynbayeva on 11/5/26.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var buffets: [Buffet] = []
    @State private var search = ""
    @State private var error: String?
    @State private var loading = false
    private var filtered: [Buffet] {
        search.isEmpty ? buffets : buffets.filter { $0.name.localizedCaseInsensitiveContains(search) || $0.location.localizedCaseInsensitiveContains(search) }
    }
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Welcome, \(session.user?.username ?? "Student")!")
                            .font(.largeTitle.bold()).foregroundStyle(.white)
                        Text("Find your campus meal and skip the queue.").foregroundStyle(.gray)
                        TextField("Search buffets", text: $search)
                            .padding(14).background(Color.darkCard, in: RoundedRectangle(cornerRadius: 14))
                        Text("Campus Buffets").font(.title2.bold()).foregroundStyle(.white)
                        if loading { ProgressView("Loading buffets...") }
                        if let error { Text(error).foregroundStyle(.red); Button("Retry") { Task { await load() } } }
                        if !loading && error == nil && filtered.isEmpty { EmptyStateView(message: "No buffets found", symbol: "fork.knife") }
                        ForEach(filtered) { buffet in
                            NavigationLink(destination: MenuView(buffet: buffet)) {
                                HStack(spacing: 14) {
                                    Image(systemName: "cup.and.saucer.fill").font(.title2).foregroundStyle(Color.accentCyan)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(buffet.name).font(.headline).foregroundStyle(.white)
                                        Label(buffet.location, systemImage: "mappin").font(.caption).foregroundStyle(.gray)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(.gray)
                                }.padding(16).background(Color.darkCard, in: RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }.padding(20)
                }.refreshable { await load() }
            }
            .navigationTitle("QuickBites")
            .task { await load() }
        }
    }
    @MainActor private func load() async {
        loading = true; error = nil
        defer { loading = false }
        do { buffets = try await APIService.shared.getBuffets() } catch { self.error = error.localizedDescription }
    }
}

struct EmptyStateView: View {
    let message: String
    let symbol: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 35)).foregroundStyle(Color.accentCyan)
            Text(message).foregroundStyle(.white).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity).padding(32).background(Color.darkCard, in: RoundedRectangle(cornerRadius: 16))
    }
}
