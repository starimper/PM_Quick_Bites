//
//  OrdersView.swift
//  QuickBites
//
//  Created by Karakat Tursynbayeva on 11/5/26.
//


import SwiftUI

struct OrdersView: View {
    @State private var orders: [QuickOrder] = []
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        if loading {
                            ProgressView("Loading orders...")
                        }

                        if let error {
                            Text(error)
                                .foregroundStyle(.red)

                            Button("Retry") {
                                Task { await load() }
                            }
                        }

                        if !loading && error == nil && orders.isEmpty {
                            EmptyStateView(
                                message: "You have no orders yet",
                                symbol: "receipt"
                            )
                        }

                        ForEach(orders) { order in
                            NavigationLink {
                                OrderDetailView(
                                    orderId: order.id,
                                    initialOrder: order
                                )
                            } label: {
                                OrderCard(order: order)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
                .refreshable {
                    await load()
                }
            }
            .navigationTitle("My Orders")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await load()
            }
        }
    }

    @MainActor
    private func load() async {
        loading = true
        error = nil
        defer { loading = false }

        do {
            orders = try await APIService.shared.myOrders()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct OrderCard: View {
    let order: QuickOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(order.buffetName)
                    .font(.headline)

                Spacer()

                Text(order.status.replacingOccurrences(
                    of: "_",
                    with: " "
                ))
                .font(.caption)
                .foregroundStyle(Color.accentCyan)
            }

            HStack {
                Label(
                    "Queue #\(order.queueNumber)",
                    systemImage: "number"
                )

                Spacer()

                Text(PriceFormat.tenge(order.total))
                    .fontWeight(.semibold)
            }
            .font(.subheadline)

            if let pickupCode = order.pickupCode {
                HStack {
                    Text("Pickup Code")
                        .font(.caption)
                        .foregroundStyle(.gray)

                    Spacer()

                    Text(pickupCode)
                        .font(.system(
                            .title3,
                            design: .monospaced
                        ))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.accentCyan)
                }
            }

            Label(
                order.pickupTime.formatted(
                    date: .abbreviated,
                    time: .shortened
                ),
                systemImage: "clock"
            )
            .font(.caption)
            .foregroundStyle(.gray)
        }
        .foregroundStyle(.white)
        .padding(16)
        .background(
            Color.darkCard,
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

struct OrderDetailView: View {
    let orderId: UUID
    let initialOrder: QuickOrder

    @State private var order: QuickOrder?
    @State private var error: String?
    @State private var processing = false
    @State private var showingFeedback = false

    private let statuses = [
        "PENDING",
        "CONFIRMED",
        "PREPARING",
        "READY",
        "COMPLETED"
    ]

    private var current: QuickOrder {
        order ?? initialOrder
    }

    private var receiptAvailable: Bool {
        !["PENDING", "CANCELLED"].contains(current.status)
    }

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    OrderCard(order: current)

                    Text("Order Progress")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    if current.status == "CANCELLED" {
                        Text("This order was cancelled.")
                            .foregroundStyle(.red)
                    } else {
                        ForEach(statuses, id: \.self) { status in
                            let completed = (
                                statuses.firstIndex(of: status) ?? 0
                            ) <= (
                                statuses.firstIndex(
                                    of: current.status
                                ) ?? 0
                            )

                            Label(
                                status.capitalized,
                                systemImage: completed
                                    ? "checkmark.circle.fill"
                                    : "circle"
                            )
                            .foregroundStyle(
                                completed
                                    ? Color.accentCyan
                                    : Color.gray
                            )
                        }
                    }

                    Text("Items")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    ForEach(current.items, id: \.mealId) { item in
                        HStack {
                            Text(
                                "\(item.quantity) × \(item.mealName)"
                            )

                            Spacer()

                            Text(
                                PriceFormat.tenge(item.lineTotal)
                            )
                        }
                        .foregroundStyle(.white)
                    }

                    Divider()

                    HStack {
                        Text("Total")
                        Spacer()
                        Text(PriceFormat.tenge(current.total))
                    }
                    .font(.headline)
                    .foregroundStyle(.white)

                    Text(
                        "Payment: \(current.paymentStatus.replacingOccurrences(of: "_", with: " "))"
                    )
                    .foregroundStyle(.gray)

                    if receiptAvailable {
                        NavigationLink {
                            OrderReceiptView(order: current)
                        } label: {
                            Label(
                                "View Electronic Receipt",
                                systemImage: "doc.text"
                            )
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Color.accentCyan,
                                in: RoundedRectangle(
                                    cornerRadius: 12
                                )
                            )
                            .foregroundStyle(.black)
                            .fontWeight(.semibold)
                        }
                    } else if current.status == "PENDING" {
                        Text(
                            "Your receipt will be available after staff confirmation."
                        )
                        .font(.caption)
                        .foregroundStyle(.gray)
                    }

                    if let error {
                        Text(error)
                            .foregroundStyle(.red)
                    }

                    if current.status == "PENDING" {
                        Button(
                            "Cancel Order",
                            role: .destructive
                        ) {
                            Task { await cancel() }
                        }
                        .disabled(processing)
                    }

                    if current.status == "COMPLETED" {
                        Button("Leave Feedback") {
                            showingFeedback = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.accentCyan)
                    }

                    Button("Refresh Status") {
                        Task { await refresh() }
                    }
                    .disabled(processing)
                }
                .padding(20)
            }
        }
        .navigationTitle("Order Details")
        .sheet(isPresented: $showingFeedback) {
            FeedbackView(orderId: orderId)
        }
        .task {
            await refresh()
        }
    }

    @MainActor
    private func refresh() async {
        do {
            let updatedOrders = try await APIService.shared.myOrders()
            order = updatedOrders.first {
                $0.id == orderId
            } ?? current
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    @MainActor
    private func cancel() async {
        processing = true
        error = nil
        defer { processing = false }

        do {
            order = try await APIService.shared.cancelOrder(
                orderId
            )
        } catch {
            self.error = error.localizedDescription
        }
    }
}
