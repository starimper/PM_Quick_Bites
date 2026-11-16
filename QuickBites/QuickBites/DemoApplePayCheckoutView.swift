//
//  DemoApplePayCheckoutView.swift
//  QuickBites
//
//  Created by Karakat Tursynbayeva on 11/15/26.
//

import Foundation

import SwiftUI

struct DemoApplePayCheckoutView: View {

    let buffetName: String
    let pickupSlot: PickupSlot
    let items: [OrderItemRequest]
    let total: Decimal

    @Environment(\.dismiss) private var dismiss

    @State private var processing = false
    @State private var errorMessage: String?
    @State private var createdOrder: QuickOrder?
    @State private var showConfirmation = false

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    header

                    orderSummary

                    paymentInformation

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }

                    Button {
                        Task {
                            await confirmDemoCheckout()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if processing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "creditcard")
                            }

                            Text(
                                processing
                                    ? "Creating Order..."
                                    : "Confirm Demo Checkout"
                            )
                            .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(17)
                        .background(
                            Color.accentCyan,
                            in: RoundedRectangle(
                                cornerRadius: 16
                            )
                        )
                        .foregroundStyle(.black)
                    }
                    .disabled(processing || items.isEmpty)

                    Text(
                        "Demo only. No money will be charged. " +
                        "Your order will remain unpaid until " +
                        "payment at pickup."
                    )
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                }
                .padding(20)
            }
        }
        .navigationTitle("Demo Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(
            isPresented: $showConfirmation
        ) {
            if let createdOrder {
                DemoOrderConfirmationView(
                    order: createdOrder
                )
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.accentCyan)

            Text("Apple Pay Demo")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            Text("Simulated checkout for QuickBites MVP")
                .font(.subheadline)
                .foregroundStyle(.gray)

            Text("DEMO MODE - NO REAL PAYMENT")
                .font(.caption.bold())
                .foregroundStyle(.orange)
        }
    }

    private var orderSummary: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("Order Summary")
                .font(.headline)
                .foregroundStyle(.white)

            summaryRow(
                "Buffet",
                buffetName
            )

            summaryRow(
                "Pickup Time",
                pickupSlot.slotTime.formatted(
                    date: .abbreviated,
                    time: .shortened
                )
            )

            summaryRow(
                "Total Items",
                String(
                    items.reduce(0) {
                        $0 + $1.quantity
                    }
                )
            )

            Divider()
                .overlay(Color.gray.opacity(0.3))

            HStack {
                Text("Total")
                    .font(.headline)

                Spacer()

                Text(
                    total.formatted(
                        .currency(code: "KZT")
                    )
                )
                .font(.title2.bold())
                .foregroundStyle(Color.accentCyan)
            }
            .foregroundStyle(.white)
        }
        .padding(18)
        .background(
            Color.darkCard,
            in: RoundedRectangle(cornerRadius: 18)
        )
    }

    private var paymentInformation: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Payment Method")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                Image(systemName: "iphone")
                    .font(.title2)
                    .foregroundStyle(Color.accentCyan)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Apple Pay Simulation")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("No card or Wallet required")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.accentCyan)
            }

            Divider()
                .overlay(Color.gray.opacity(0.3))

            Text("Recorded payment method: Pay at Pickup")
                .font(.subheadline)
                .foregroundStyle(.gray)

            Text("Recorded payment status: Pending")
                .font(.subheadline)
                .foregroundStyle(.orange)
        }
        .padding(18)
        .background(
            Color.darkCard,
            in: RoundedRectangle(cornerRadius: 18)
        )
    }

    private func summaryRow(
        _ title: String,
        _ value: String
    ) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(.gray)

            Spacer()

            Text(value)
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    @MainActor
    private func confirmDemoCheckout() async {
        guard !processing else {
            return
        }

        processing = true
        errorMessage = nil

        defer {
            processing = false
        }

        do {
            let preview = try await APIService.shared
                .previewDemoApplePay(
                    slotId: pickupSlot.id,
                    items: items
                )

            guard preview.status == "READY" else {
                throw APIError.serverError(
                    400,
                    "Demo checkout is unavailable."
                )
            }

            let order = try await APIService.shared
                .createOrder(
                    slotId: pickupSlot.id,
                    items: items
                )

            createdOrder = order
            showConfirmation = true

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
