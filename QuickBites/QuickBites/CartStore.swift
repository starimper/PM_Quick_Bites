//
//  CartStore.swift
//  QuickBites
//
//  Created by Karakat Tursynbayeva on 11/5/26.
//

import SwiftUI
import Combine

struct CartLine: Identifiable {
    let meal: Meal
    var quantity: Int
    var id: UUID { meal.id }
}
@MainActor
final class CartStore: ObservableObject {
    @Published private(set) var buffet: Buffet?
    @Published private(set) var lines: [CartLine] = []
    var count: Int { lines.reduce(0) { $0 + $1.quantity } }
    var total: Decimal { lines.reduce(Decimal.zero) { $0 + $1.meal.price * Decimal($1.quantity) } }
    func quantity(for meal: Meal) -> Int { lines.first(where: { $0.id == meal.id })?.quantity ?? 0 }
    func add(_ meal: Meal, from buffet: Buffet) {
        guard meal.available else { return }
        if self.buffet?.id != buffet.id { lines = []; self.buffet = buffet }
        if let index = lines.firstIndex(where: { $0.id == meal.id }) {
            if lines[index].quantity < 20 { lines[index].quantity += 1 }
        } else if lines.count < 20 { lines.append(CartLine(meal: meal, quantity: 1)) }
    }
    func remove(_ meal: Meal) {
        guard let index = lines.firstIndex(where: { $0.id == meal.id }) else { return }
        if lines[index].quantity > 1 { lines[index].quantity -= 1 } else { lines.remove(at: index) }
        if lines.isEmpty { buffet = nil }
    }
    func clear() { buffet = nil; lines = [] }
}

enum PriceFormat {
    static func tenge(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        return "\(number.stringValue) ₸"
    }
}
