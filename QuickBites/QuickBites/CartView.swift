//
//  CartView.swift
//  QuickBites
//
//  Created by Karakat Tursynbayeva on 11/5/26.
//


import Foundation
import SwiftUI

struct CartView: View {

    @EnvironmentObject private var cart: CartStore

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(
                        alignment: .leading,
                        spacing: 18
                    ) {
                        if cart.lines.isEmpty {
                            EmptyStateView(
                                message: "Your cart is empty. Explore campus buffets to add meals.",
                                symbol: "cart"
                            )
                        } else {
                            Text(cart.buffet?.name ?? "Your Cart")
                                .font(.title2.bold())
                                .foregroundStyle(.white)

                            ForEach(cart.lines) { line in
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(line.meal.name)
                                            .font(.headline)
                                            .foregroundStyle(.white)

                                        Text(
                                            PriceFormat.tenge(
                                                line.meal.price * Decimal(line.quantity)
                                            )
                                        )
                                        .foregroundStyle(Color.accentCyan)
                                    }

                                    Spacer()

                                    Button {
                                        cart.remove(line.meal)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title3)
                                    }

                                    Text("\(line.quantity)")
                                        .foregroundStyle(.white)
                                        .frame(minWidth: 20)

                                    Button {
                                        if let buffet = cart.buffet {
                                            cart.add(line.meal, from: buffet)
                                        }
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title3)
                                    }
                                    .disabled(line.quantity >= 20)
                                }
                                .padding(16)
                                .background(
                                    Color.darkCard,
                                    in: RoundedRectangle(cornerRadius: 16)
                                )
                            }

                            HStack {
                                Text("Total")
                                    .foregroundStyle(.white)

                                Spacer()

                                Text(
                                    PriceFormat.tenge(cart.total)
                                )
                                .font(.title2.bold())
                                .foregroundStyle(Color.accentCyan)
                            }
                            .padding(.vertical, 8)

                            NavigationLink {
                                CheckoutView()
                            } label: {
                                Text("Continue to Checkout")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding(16)
                                    .foregroundStyle(.black)
                                    .background(
                                        Color.accentCyan,
                                        in: RoundedRectangle(
                                            cornerRadius: 14
                                        )
                                    )
                            }

                            Button(
                                "Clear Cart",
                                role: .destructive
                            ) {
                                cart.clear()
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Cart")
        }
    }
}

enum CheckoutPaymentMethod: String, CaseIterable {
    case payAtPickup = "Pay at Pickup"
    case applePayDemo = "Apple Pay Demo"

    var symbol: String {
        switch self {
        case .payAtPickup:
            return "banknote"
        case .applePayDemo:
            return "creditcard.fill"
        }
    }

    var description: String {
        switch self {
        case .payAtPickup:
            return "Pay when collecting your order."
        case .applePayDemo:
            return "Simulated checkout. No real payment."
        }
    }
}

struct CheckoutView: View {

    @EnvironmentObject private var cart: CartStore
    @Environment(\.dismiss) private var dismiss

    @State private var slots: [PickupSlot] = []
    @State private var selectedSlot: UUID?
    @State private var selectedPaymentMethod:
        CheckoutPaymentMethod = .payAtPickup

    @State private var createdOrder: QuickOrder?

    @State private var loading = false
    @State private var submitting = false
    @State private var error: String?

    @State private var showDemoCheckout = false

    private var selectedPickupSlot: PickupSlot? {
        slots.first {
            $0.id == selectedSlot
        }
    }

    private var requestItems: [OrderItemRequest] {
        cart.lines.map {
            OrderItemRequest(
                mealId: $0.meal.id,
                quantity: $0.quantity
            )
        }
    }

    private var canCheckout: Bool {
        selectedPickupSlot != nil &&
        !cart.lines.isEmpty &&
        !submitting &&
        !loading
    }

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {
                    pickupSection

                    paymentSection

                    totalSection

                    if let error {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }

                    checkoutButton
                }
                .padding(20)
            }
            .refreshable {
                await load()
            }
        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
        .navigationDestination(
            isPresented: $showDemoCheckout
        ) {
            if let buffet = cart.buffet,
               let slot = selectedPickupSlot {
                DemoApplePayCheckoutView(
                    buffetName: buffet.name,
                    pickupSlot: slot,
                    items: requestItems,
                    total: cart.total
                )
            }
        }
        .alert(
            "Order Placed",
            isPresented: Binding(
                get: {
                    createdOrder != nil
                },
                set: {
                    if !$0 {
                        createdOrder = nil
                    }
                }
            )
        ) {
            Button("OK") {
                dismiss()
            }
        } message: {
            if let order = createdOrder {
                Text(
                    "Your order has been placed successfully.\n\n" +
                    "Pickup Code: \(order.pickupCode ?? "Unavailable")\n" +
                    "Queue Number: \(String(format: "%03d", order.queueNumber))\n\n" +
                    "Payment Method: Pay at Pickup\n" +
                    "Payment Status: \(order.paymentStatus)\n\n" +
                    "Track your order in the Orders tab."
                )
            }
        }
    }

    private var pickupSection: some View {
        VStack(
            alignment: .leading,
            spacing: 14
        ) {
            Text("Pickup Time")
                .font(.title2.bold())
                .foregroundStyle(.white)

            if loading {
                ProgressView("Loading pickup times...")
                    .tint(Color.accentCyan)
            }

            if !loading && slots.isEmpty {
                EmptyStateView(
                    message: "No available pickup slots. Please check again later.",
                    symbol: "clock"
                )
            }

            ForEach(slots) { slot in
                Button {
                    selectedSlot = slot.id
                } label: {
                    HStack(spacing: 12) {
                        VStack(
                            alignment: .leading,
                            spacing: 6
                        ) {
                            Text(
                                slot.slotTime.formatted(
                                    date: .abbreviated,
                                    time: .shortened
                                )
                            )
                            .fontWeight(.semibold)

                            Text(
                                "\(slot.remaining) spots remaining"
                            )
                            .font(.caption)
                            .foregroundStyle(.gray)
                        }

                        Spacer()

                        Image(
                            systemName:
                                selectedSlot == slot.id
                                ? "checkmark.circle.fill"
                                : "circle"
                        )
                        .font(.title3)
                        .foregroundStyle(Color.accentCyan)
                    }
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(
                        selectedSlot == slot.id
                            ? Color.accentCyan.opacity(0.20)
                            : Color.darkCard,
                        in: RoundedRectangle(
                            cornerRadius: 14
                        )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var paymentSection: some View {
        VStack(
            alignment: .leading,
            spacing: 14
        ) {
            Text("Payment Method")
                .font(.title2.bold())
                .foregroundStyle(.white)

            ForEach(
                CheckoutPaymentMethod.allCases,
                id: \.self
            ) { method in
                Button {
                    selectedPaymentMethod = method
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: method.symbol)
                            .font(.title2)
                            .foregroundStyle(Color.accentCyan)
                            .frame(width: 32)

                        VStack(
                            alignment: .leading,
                            spacing: 5
                        ) {
                            Text(method.rawValue)
                                .font(.headline)
                                .foregroundStyle(.white)

                            Text(method.description)
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }

                        Spacer()

                        Image(
                            systemName:
                                selectedPaymentMethod == method
                                ? "checkmark.circle.fill"
                                : "circle"
                        )
                        .font(.title3)
                        .foregroundStyle(Color.accentCyan)
                    }
                    .padding(16)
                    .background(
                        selectedPaymentMethod == method
                            ? Color.accentCyan.opacity(0.20)
                            : Color.darkCard,
                        in: RoundedRectangle(
                            cornerRadius: 14
                        )
                    )
                }
                .buttonStyle(.plain)
            }

            if selectedPaymentMethod == .applePayDemo {
                Text(
                    "Demo mode only. No real payment will be processed. " +
                    "The order will be recorded as Pay at Pickup."
                )
                .font(.caption)
                .foregroundStyle(.orange)
            } else {
                Text(
                    "You will pay when collecting your order."
                )
                .font(.caption)
                .foregroundStyle(.gray)
            }
        }
    }

    private var totalSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Total")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                Text(
                    PriceFormat.tenge(cart.total)
                )
                .font(.title2.bold())
                .foregroundStyle(Color.accentCyan)
            }

            Divider()
                .overlay(Color.gray.opacity(0.3))

            HStack {
                Text("Items")
                    .foregroundStyle(.gray)

                Spacer()

                Text(
                    "\(cart.lines.reduce(0) { $0 + $1.quantity })"
                )
                .foregroundStyle(.white)
            }
        }
        .padding(18)
        .background(
            Color.darkCard,
            in: RoundedRectangle(
                cornerRadius: 16
            )
        )
    }

    private var checkoutButton: some View {
        Button {
            switch selectedPaymentMethod {
            case .payAtPickup:
                Task {
                    await placeOrder()
                }

            case .applePayDemo:
                showDemoCheckout = true
            }
        } label: {
            HStack(spacing: 10) {
                if submitting {
                    ProgressView()
                        .tint(.black)
                } else {
                    Image(
                        systemName:
                            selectedPaymentMethod == .applePayDemo
                            ? "creditcard.fill"
                            : "bag.fill"
                    )
                }

                Text(
                    submitting
                        ? "Placing Order..."
                        : selectedPaymentMethod == .applePayDemo
                            ? "Continue to Demo Payment"
                            : "Place Order"
                )
                .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .foregroundStyle(.black)
            .background(
                Color.accentCyan,
                in: RoundedRectangle(
                    cornerRadius: 14
                )
            )
        }
        .disabled(!canCheckout)
        .opacity(canCheckout ? 1 : 0.5)
    }

    @MainActor
    private func load() async {
        guard let buffet = cart.buffet else {
            return
        }

        loading = true
        error = nil

        defer {
            loading = false
        }

        do {
            let allSlots = try await APIService.shared.getSlots(
                buffetId: buffet.id
            )

            var calendar = Calendar(
                identifier: .gregorian
            )

            calendar.timeZone = TimeZone(
                identifier: "Asia/Almaty"
            )!

            let today = calendar.startOfDay(
                for: Date()
            )

            slots = allSlots
                .filter { slot in
                    calendar.isDate(
                        slot.slotTime,
                        inSameDayAs: today
                    ) &&
                    slot.remaining > 0 &&
                    slot.slotTime > Date()
                }
                .sorted {
                    $0.slotTime < $1.slotTime
                }

            selectedSlot = nil

        } catch {
            self.error = error.localizedDescription
        }
    }

    @MainActor
    private func placeOrder() async {
        guard let selectedSlot,
              !cart.lines.isEmpty,
              !submitting else {
            return
        }

        submitting = true
        error = nil

        defer {
            submitting = false
        }

        do {
            let result = try await APIService.shared.createOrder(
                slotId: selectedSlot,
                items: requestItems
            )

            cart.clear()
            createdOrder = result

        } catch {
            self.error = error.localizedDescription
        }
    }
}
