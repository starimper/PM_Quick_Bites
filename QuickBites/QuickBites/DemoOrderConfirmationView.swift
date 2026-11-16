//
//  DemoOrderConfirmationView.swift
//  QuickBites
//
//  Created by Karakat Tursynbayeva on 11/15/26.
//

import Foundation

import SwiftUI

struct DemoOrderConfirmationView: View {

    let order: QuickOrder

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.accentCyan)

                    Text("Order Created")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("Your order was created successfully.")
                        .foregroundStyle(.gray)

                    Text("No payment was charged.")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)

                    VStack(spacing: 16) {
                        detailRow(
                            "Order Number",
                            String(
                                format: "#%03d",
                                order.queueNumber
                            )
                        )

                        detailRow(
                            "Buffet",
                            order.buffetName
                        )

                        detailRow(
                            "Pickup Code",
                            order.pickupCode ?? "Not available"
                        )

                        detailRow(
                            "Pickup Time",
                            order.pickupTime.formatted(
                                date: .abbreviated,
                                time: .shortened
                            )
                        )

                        detailRow(
                            "Order Status",
                            order.status
                        )

                        detailRow(
                            "Payment Method",
                            "Pay at Pickup"
                        )

                        detailRow(
                            "Payment Status",
                            order.paymentStatus
                        )

                        detailRow(
                            "Total",
                            order.total.formatted(
                                .currency(code: "KZT")
                            )
                        )
                    }
                    .padding(18)
                    .background(
                        Color.darkCard,
                        in: RoundedRectangle(
                            cornerRadius: 18
                        )
                    )

                    Text(
                        "This was a demo checkout. " +
                        "Please pay when collecting your order."
                    )
                    .font(.footnote)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                }
                .padding(20)
            }
        }
        .navigationTitle("Order Confirmation")
        .navigationBarBackButtonHidden()
    }

    private func detailRow(
        _ title: String,
        _ value: String
    ) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(.gray)

            Spacer()

            Text(value)
                .foregroundStyle(.white)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}
