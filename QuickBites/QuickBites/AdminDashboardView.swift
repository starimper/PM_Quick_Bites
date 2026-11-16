//
//  AdminDashboardView.swift
//  QuickBites
//
//  Created by Karakat Tursynbayeva on 11/5/26.
//

import SwiftUI

struct AdminDashboardView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var staffName = ""
    @State private var staffEmail = ""
    @State private var staffPassword = ""
    @State private var buffetName = ""
    @State private var buffetLocation = ""
    @State private var buffetOwner = ""
    @State private var userId = ""
    @State private var active = true
    @State private var buffets: [Buffet] = []
    @State private var message: String?
    @State private var error: String?
    @State private var busy = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Administrator") {
                    Text(session.user?.email ?? "")
                    Button("Sign Out") { session.signOut() }
                }
                Section("Create Staff Account") {
                    TextField("Full name", text: $staffName)
                    TextField("University email", text: $staffEmail).textInputAutocapitalization(.never)
                    SecureField("Temporary password (10+ characters)", text: $staffPassword)
                    Button("Create Staff") { Task { await createStaff() } }.disabled(busy)
                }
                Section("Create Buffet") {
                    TextField("Buffet name", text: $buffetName)
                    TextField("Location", text: $buffetLocation)
                    TextField("Staff owner UUID", text: $buffetOwner).textInputAutocapitalization(.never)
                    Button("Create Buffet") { Task { await createBuffet() } }.disabled(busy)
                }
                Section("Update User Status") {
                    TextField("User UUID", text: $userId).textInputAutocapitalization(.never)
                    Toggle("Account Active", isOn: $active)
                    Button("Update User") { Task { await updateUser() } }.disabled(busy)
                }
                Section("All Buffets") {
                    ForEach(buffets) { buffet in
                        NavigationLink(destination: StaffBuffetView(buffet: buffet)) {
                            VStack(alignment: .leading) {
                                Text(buffet.name)
                                Text(buffet.location).font(.caption).foregroundStyle(.gray)
                                Text("Owner: \(buffet.ownerId.uuidString)").font(.caption2).textSelection(.enabled)
                            }
                        }
                    }
                }
                if let message { Section { Text(message).foregroundStyle(.green) } }
                if let error { Section { Text(error).foregroundStyle(.red) } }
            }
            .navigationTitle("Admin Dashboard")
            .refreshable { await load() }
            .task { await load() }
        }
    }
    @MainActor private func load() async {
        do { buffets = try await APIService.shared.getBuffets() }
        catch { self.error = error.localizedDescription }
    }
    @MainActor private func createStaff() async {
        busy = true; error = nil; message = nil
        defer { busy = false }
        do {
            let staff = try await APIService.shared.createStaff(username: staffName, email: staffEmail, password: staffPassword)
            message = "Staff created. Owner UUID: \(staff.id.uuidString)"
            buffetOwner = staff.id.uuidString
            staffPassword = ""
        } catch { self.error = error.localizedDescription }
    }
    @MainActor private func createBuffet() async {
        guard let owner = UUID(uuidString: buffetOwner) else { error = "Enter a valid staff owner UUID."; return }
        busy = true; error = nil; message = nil
        defer { busy = false }
        do {
            let buffet = try await APIService.shared.createBuffet(name: buffetName, location: buffetLocation, ownerId: owner)
            message = "Buffet created: \(buffet.name)"
            await load()
        } catch { self.error = error.localizedDescription }
    }
    @MainActor private func updateUser() async {
        guard let id = UUID(uuidString: userId) else { error = "Enter a valid user UUID."; return }
        busy = true; error = nil; message = nil
        defer { busy = false }
        do {
            let user = try await APIService.shared.setUserActive(id, active: active)
            message = "\(user.username) is now \(user.active ? "active" : "inactive")."
        } catch { self.error = error.localizedDescription }
    }
}
