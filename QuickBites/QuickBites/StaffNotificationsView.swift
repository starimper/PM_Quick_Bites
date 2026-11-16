//
//  StaffNotificationsView.swift
//  QuickBites
//
//  Created by Karakat Tursynbayeva on 11/15/26.
//

import Foundation

import SwiftUI

struct StaffNotificationsView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var notifications: [NotificationItem] = []
    @State private var errorMessage: String?
    @State private var loading = false
    @State private var processing = false

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if loading && notifications.isEmpty {
                        ProgressView("Loading notifications...")
                            .tint(Color.accentCyan)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)

                        Button("Retry") {
                            Task {
                                await load()
                            }
                        }
                    }

                    if !loading &&
                        notifications.isEmpty &&
                        errorMessage == nil {
                        EmptyStateView(
                            message: "No notifications yet",
                            symbol: "bell"
                        )
                    }

                    ForEach(notifications) { item in
                        Button {
                            Task {
                                await markRead(item)
                            }
                        } label: {
                            HStack(
                                alignment: .top,
                                spacing: 12
                            ) {
                                Image(
                                    systemName: symbol(for: item.type)
                                )
                                .font(.title3)
                                .foregroundStyle(Color.accentCyan)
                                .frame(width: 28)

                                VStack(
                                    alignment: .leading,
                                    spacing: 7
                                ) {
                                    Text(title(for: item.type))
                                        .font(.headline)
                                        .foregroundStyle(.white)

                                    Text(item.message)
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.leading)

                                    Text(
                                        item.createdAt.formatted(
                                            date: .abbreviated,
                                            time: .shortened
                                        )
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                }

                                Spacer(minLength: 4)

                                if !item.read {
                                    Circle()
                                        .fill(Color.accentCyan)
                                        .frame(
                                            width: 9,
                                            height: 9
                                        )
                                }
                            }
                            .padding(16)
                            .background(
                                Color.darkCard,
                                in: RoundedRectangle(
                                    cornerRadius: 16
                                )
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(item.read || processing)
                    }
                }
                .padding(20)
            }
            .refreshable {
                await load()
            }
        }
        .navigationTitle("Notifications")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Mark All as Read") {
                    Task {
                        await markAllRead()
                    }
                }
                .disabled(
                    processing ||
                    !notifications.contains(where: { !$0.read })
                )
            }
        }
        .task {
            await load()

            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(15))
                } catch {
                    break
                }

                if scenePhase == .active {
                    await load()
                }
            }
        }
    }

    @MainActor
    private func load() async {
        guard !processing else {
            return
        }

        loading = true

        defer {
            loading = false
        }

        do {
            notifications = try await APIService.shared.notifications()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func markRead(_ item: NotificationItem) async {
        guard !item.read && !processing else {
            return
        }

        processing = true

        defer {
            processing = false
        }

        do {
            _ = try await APIService.shared.markNotificationRead(
                item.id
            )

            notifications = try await APIService.shared.notifications()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func markAllRead() async {
        guard !processing else {
            return
        }

        processing = true

        defer {
            processing = false
        }

        do {
            for item in notifications where !item.read {
                _ = try await APIService.shared.markNotificationRead(
                    item.id
                )
            }

            notifications = try await APIService.shared.notifications()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func symbol(for type: String) -> String {
        switch type {
        case "NEW_ORDER":
            return "bag.badge.plus"
        case "ORDER_CANCELLED":
            return "xmark.circle"
        case "NEW_FEEDBACK":
            return "text.bubble"
        case "ORDER_READY":
            return "checkmark.circle"
        default:
            return "bell"
        }
    }

    private func title(for type: String) -> String {
        switch type {
        case "NEW_ORDER":
            return "New Order"
        case "ORDER_CANCELLED":
            return "Order Cancelled"
        case "NEW_FEEDBACK":
            return "New Customer Feedback"
        case "ORDER_READY":
            return "Order Ready"
        default:
            return "Notification"
        }
    }
}
