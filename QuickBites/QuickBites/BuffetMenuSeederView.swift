//
//  BuffetMenuSeederView.swift
//  QuickBites
//
//  Created by Karakat Tursynbayeva on 11/12/26.
//

import Foundation

import SwiftUI

struct SeedMeal: Identifiable {
    let name: String
    let category: String
    let price: Int
    let capacity: Int

    var id: String { name }

    var description: String {
        category
    }
}

enum ToleBiMenu {
    static let items: [SeedMeal] = [
        SeedMeal(name: "Espresso", category: "Coffee", price: 650, capacity: 30),
        SeedMeal(name: "Latte", category: "Coffee", price: 850, capacity: 30),
        SeedMeal(name: "Iced Latte", category: "Coffee", price: 950, capacity: 25),
        SeedMeal(name: "Americano", category: "Coffee", price: 650, capacity: 30),
        SeedMeal(name: "Cappuccino", category: "Coffee", price: 850, capacity: 30),
        SeedMeal(name: "Iced Americano", category: "Coffee", price: 750, capacity: 25),
        SeedMeal(name: "Iced Cappuccino", category: "Coffee", price: 950, capacity: 25),
        SeedMeal(name: "Strawberry Smoothie", category: "Drinks", price: 1200, capacity: 20),
        SeedMeal(name: "Cocoa", category: "Drinks", price: 750, capacity: 25),
        SeedMeal(name: "Tea", category: "Drinks", price: 350, capacity: 50),
        SeedMeal(name: "Juice", category: "Drinks", price: 450, capacity: 40),

        SeedMeal(name: "Sandwich", category: "Food", price: 650, capacity: 30),
        SeedMeal(name: "Chicken Croissant", category: "Food", price: 1100, capacity: 20),
        SeedMeal(name: "Chicken Burger", category: "Food", price: 1300, capacity: 20),
        SeedMeal(name: "Beef Burger", category: "Food", price: 1400, capacity: 20),
        SeedMeal(name: "Croissant", category: "Bakery", price: 700, capacity: 25),
        SeedMeal(name: "Berliner", category: "Bakery", price: 600, capacity: 20),
        SeedMeal(name: "Pancakes", category: "Food", price: 700, capacity: 25),
        SeedMeal(name: "Chicken Pancakes", category: "Food", price: 1100, capacity: 20),
        SeedMeal(name: "Cottage Cheese", category: "Food", price: 750, capacity: 20),
        SeedMeal(name: "Chocolate Cake", category: "Desserts", price: 1300, capacity: 15),
        SeedMeal(name: "Cake", category: "Desserts", price: 1200, capacity: 15),
        SeedMeal(name: "Tartlet", category: "Desserts", price: 950, capacity: 20),
        SeedMeal(name: "Muffin", category: "Desserts", price: 650, capacity: 25),
        SeedMeal(name: "Chocolate Potato Cake", category: "Desserts", price: 650, capacity: 20)
    ]
}

struct BuffetMenuSeederView: View {
    let buffet: Buffet

    @State private var isImporting = false
    @State private var progress = 0
    @State private var resultMessage: String?
    @State private var failedItems: [String] = []

    private var total: Int {
        ToleBiMenu.items.count
    }

    var body: some View {
        List {
            Section {
                Text(buffet.name)
                    .font(.headline)

                Text(buffet.location)
                    .foregroundStyle(.secondary)

                Text("Import the prepared menu into the database.")
                    .font(.subheadline)

                Text("Existing meals with matching names will be skipped.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Menu Preview") {
                ForEach(ToleBiMenu.items) { meal in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(meal.name)
                                .font(.subheadline.weight(.medium))

                            Text(meal.category)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(meal.price) ₸")
                            .foregroundStyle(Color.accentCyan)
                    }
                }
            }

            Section {
                if isImporting {
                    ProgressView(
                        value: Double(progress),
                        total: Double(total)
                    )

                    Text("Processing \(progress) of \(total)")
                        .font(.caption)
                }

                Button {
                    Task {
                        await importMenu()
                    }
                } label: {
                    HStack {
                        Spacer()

                        if isImporting {
                            ProgressView()
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }

                        Text("Import Menu")
                            .fontWeight(.semibold)

                        Spacer()
                    }
                }
                .disabled(isImporting)

                if let resultMessage {
                    Text(resultMessage)
                        .font(.subheadline)
                }

                if !failedItems.isEmpty {
                    Text("Failed items:")
                        .font(.headline)

                    ForEach(failedItems, id: \.self) { item in
                        Text(item)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle("Import Menu")
        .tint(Color.accentCyan)
    }

    @MainActor
    private func importMenu() async {
        guard !isImporting else { return }

        isImporting = true
        progress = 0
        resultMessage = nil
        failedItems = []

        defer {
            isImporting = false
        }

        do {
            let existingMenu = try await APIService.shared.getMenu(
                buffetId: buffet.id
            )

            var existingNames = Set(
                existingMenu.meals.map {
                    $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        .lowercased()
                }
            )

            var created = 0
            var skipped = 0

            for meal in ToleBiMenu.items {
                let normalizedName = meal.name.lowercased()

                if existingNames.contains(normalizedName) {
                    skipped += 1
                    progress += 1
                    continue
                }

                do {
                    _ = try await APIService.shared.createMeal(
                        buffetId: buffet.id,
                        name: meal.name,
                        description: meal.description,
                        price: Decimal(meal.price),
                        capacity: meal.capacity
                    )

                    existingNames.insert(normalizedName)
                    created += 1
                } catch {
                    failedItems.append(
                        "\(meal.name): \(error.localizedDescription)"
                    )
                }

                progress += 1
            }

            resultMessage = """
            Created: \(created)
            Skipped: \(skipped)
            Failed: \(failedItems.count)
            """
        } catch {
            resultMessage = error.localizedDescription
        }
    }
}

