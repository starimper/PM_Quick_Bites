//
//  OrderReceiptView.swift
//  QuickBites
//
//  Created by Karakat Tursynbayeva on 11/12/26.
//

import Foundation

import SwiftUI

struct OrderReceiptView: View {
    let order: QuickOrder

    private var isPaid: Bool {
        order.paymentStatus == "PAID"
    }

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)

                        Text("QuickBites")
                            .font(.largeTitle.bold())

                        Text("Electronic Order Receipt")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    VStack(spacing: 8) {
                        Text("PICKUP CODE")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        Text(order.pickupCode ?? "Unavailable")
                            .font(.system(
                                size: 46,
                                weight: .bold,
                                design: .monospaced
                            ))

                        Text(
                            "Show this code to the buffet staff"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Divider()

                    VStack(spacing: 14) {
                        receiptRow(
                            "Buffet",
                            order.buffetName
                        )

                        receiptRow(
                            "Customer",
                            order.customerName ?? "Student"
                        )

                        receiptRow(
                            "Order Number",
                            "#\(order.queueNumber)"
                        )

                        receiptRow(
                            "Order Date",
                            order.orderedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Not available"
                        )

                        receiptRow(
                            "Pickup Time",
                            order.pickupTime.formatted(
                                date: .abbreviated,
                                time: .shortened
                            )
                        )

                        receiptRow(
                            "Order Status",
                            order.status.capitalized
                        )
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 14) {
                        Text("ORDER ITEMS")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        ForEach(
                            order.items,
                            id: \.mealId
                        ) { item in
                            receiptRow(
                                "\(item.mealName) × \(item.quantity)",
                                PriceFormat.tenge(item.lineTotal)
                            )
                        }
                    }

                    Divider()

                    receiptRow(
                        "Total",
                        PriceFormat.tenge(order.total)
                    )
                    .font(.headline)

                    receiptRow(
                        "Payment",
                        isPaid
                            ? "Paid"
                            : "Payment due at pickup"
                    )

                    Divider()

                    Text(
                        "This document confirms your order. It is not a fiscal receipt or proof of payment."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                }
                .padding(24)
                .foregroundStyle(.black)
                .background(
                    Color.white,
                    in: RoundedRectangle(
                        cornerRadius: 20
                    )
                )
                .padding(16)
            }
        }
        .navigationTitle("Receipt")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func receiptRow(
        _ title: String,
        _ value: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}
