import SwiftUI

struct NotificationsView: View {
    @State private var notifications: [NotificationItem] = []
    @State private var error: String?
    @State private var loading = false
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 12) {
                        if loading { ProgressView("Loading notifications...") }
                        if let error { Text(error).foregroundStyle(.red) }
                        if !loading && notifications.isEmpty && error == nil { EmptyStateView(message: "No notifications yet", symbol: "bell") }
                        ForEach(notifications) { item in
                            Button { Task { await markRead(item.id) } } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: item.read ? "bell" : "bell.badge.fill").foregroundStyle(Color.accentCyan)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(item.message).foregroundStyle(.white).multilineTextAlignment(.leading)
                                        Text(item.createdAt.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.gray)
                                        if !item.read { Text("Tap to mark as read").font(.caption).foregroundStyle(Color.accentCyan) }
                                    }
                                    Spacer()
                                }.padding(16).background(Color.darkCard, in: RoundedRectangle(cornerRadius: 16))
                            }.disabled(item.read)
                        }
                    }.padding(20)
                }.refreshable { await load() }
            }.navigationTitle("Notifications").task { await load() }
        }
    }
    @MainActor private func load() async {
        loading = true; error = nil
        defer { loading = false }
        do { notifications = try await APIService.shared.notifications() }
        catch { self.error = error.localizedDescription }
    }
    @MainActor private func markRead(_ id: UUID) async {
        do { _ = try await APIService.shared.markNotificationRead(id); await load() }
        catch { self.error = error.localizedDescription }
    }
}

struct FeedbackView: View {
    let orderId: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var rating = "HAPPY"
    @State private var comment = ""
    @State private var error: String?
    @State private var submitted = false
    @State private var submitting = false
    var body: some View {
        NavigationStack {
            Form {
                Picker("How was your order?", selection: $rating) {
                    Text("Happy").tag("HAPPY")
                    Text("Neutral").tag("NEUTRAL")
                    Text("Sad").tag("SAD")
                }.pickerStyle(.segmented)
                Section("Comment") { TextEditor(text: $comment).frame(minHeight: 120) }
                if let error { Text(error).foregroundStyle(.red) }
                Button("Submit Feedback") { Task { await submit() } }.disabled(submitting || comment.count > 2000)
            }
            .navigationTitle("Feedback")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Close") { dismiss() } } }
            .alert("Thank you!", isPresented: $submitted) { Button("Done") { dismiss() } }
        }
        .preferredColorScheme(.dark)
    }
    @MainActor private func submit() async {
        submitting = true; error = nil
        defer { submitting = false }
        do { _ = try await APIService.shared.submitFeedback(orderId: orderId, rating: rating, comment: comment); submitted = true }
        catch { self.error = error.localizedDescription }
    }
}
