//
//  APIServic.swift
//  QuickBites
//
//  Created by Karakat Tursynbayeva on 11/5/26.
//

import Foundation

struct AuthUser: Codable, Identifiable {
    let id: UUID
    let username: String
    let email: String
    let role: String
}

struct AuthResponse: Decodable {
    let tokenType: String
    let accessToken: String
    let expiresAt: Date
    let user: AuthUser
}

struct RegisterRequest: Encodable {
    let username: String
    let email: String
    let password: String
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct Buffet: Codable, Identifiable {
    let id: UUID
    let name: String
    let location: String
    let ownerId: UUID
}

struct Meal: Decodable, Identifiable {
    let id: UUID
    let name: String
    let description: String?
    let photoUrl: String?
    let price: Decimal
    let capacity: Int?
    let reservedCount: Int
    let available: Bool
}

struct BuffetMenu: Decodable {
    let buffetId: UUID
    let buffetName: String
    let date: String
    let meals: [Meal]
}

struct PickupSlot: Decodable, Identifiable {
    let id: UUID
    let slotTime: Date
    let capacity: Int
    let remaining: Int
}

struct OrderItemRequest: Encodable {
    let mealId: UUID
    let quantity: Int
}

struct CreateOrderRequest: Encodable {
    let pickupSlotId: UUID
    let items: [OrderItemRequest]
    let paymentMethod: String
}

struct OrderLine: Decodable {
    let mealId: UUID
    let mealName: String
    let quantity: Int
    let unitPrice: Decimal
    let lineTotal: Decimal
}


struct QuickOrder: Decodable, Identifiable {
    let id: UUID
    let buffetId: UUID
    let buffetName: String
    let queueNumber: Int

    let pickupCode: String?
    let customerName: String?
    let customerEmail: String?

    let pickupTime: Date
    let status: String
    let paymentMethod: String
    let paymentStatus: String
    let total: Decimal

    let orderedAt: Date?
    let items: [OrderLine]
}


struct OrderPage: Decodable {
    let content: [QuickOrder]
    let page: Int
    let size: Int
    let totalElements: Int64
    let totalPages: Int
}

struct OrderStatusRequest: Encodable {
    let status: String
}

struct NotificationItem: Decodable, Identifiable {
    let id: UUID
    let type: String
    let message: String
    let read: Bool
    let createdAt: Date
}


struct FeedbackItem: Decodable, Identifiable {
    let id: UUID
    let orderId: UUID
    let emojiRating: String
    let comment: String?
    let flagged: Bool
    let createdAt: Date?
}


struct FeedbackRequest: Encodable {
    let emojiRating: String
    let comment: String
}

struct FlagRequest: Encodable {
    let flagged: Bool
}

struct CreateMealRequest: Encodable {
    let name: String
    let description: String
    let photoUrl: String?
    let nutritionInfo: [String: String]
    let price: Decimal
    let capacity: Int?
}

struct UpdateMealRequest: Encodable {
    let name: String?
    let description: String?
    let photoUrl: String?
    let price: Decimal?
    let capacity: Int?
}

struct AvailabilityRequest: Encodable {
    let available: Bool
}

struct CreateSlotRequest: Encodable {
    let slotTime: Date
    let capacity: Int
}

struct CreateStaffRequest: Encodable {
    let username: String
    let email: String
    let temporaryPassword: String
}

struct StaffResponse: Decodable {
    let id: UUID
    let username: String
    let email: String
    let role: String
}

struct CreateBuffetRequest: Encodable {
    let name: String
    let location: String
    let ownerId: UUID
}

struct ActiveRequest: Encodable {
    let active: Bool
}

struct UserStatusResponse: Decodable {
    let id: UUID
    let username: String
    let email: String
    let role: String
    let active: Bool
}

struct EmptyResponse: Decodable {}

struct APIProblem: Decodable {
    let title: String?
    let detail: String?
}

enum APIError: LocalizedError {
    case invalidResponse
    case serverError(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response."
        case .serverError(let code, let message):
            return "HTTP \(code): \(message)"
        }
    }
}

final class APIService {
    static let shared = APIService()

    // The simulator uses localhost to access the Mac backend.
    // A physical iPhone requires the Mac's LAN IP address.
    private let baseURL = URL(
        string: "http://localhost:8080/api"
    )!

    private init() {}

    private func url(
        _ path: String,
        query: [URLQueryItem] = []
    ) -> URL {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )!

        if !query.isEmpty {
            components.queryItems = query
        }

        return components.url!
    }

    private func request(
        _ path: String,
        method: String = "GET",
        authenticated: Bool = true,
        query: [URLQueryItem] = []
    ) throws -> URLRequest {
        var result = URLRequest(
            url: url(path, query: query)
        )

        result.httpMethod = method
        result.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        if authenticated {
            guard let token = KeychainManager.readToken() else {
                throw APIError.serverError(
                    401,
                    "Please sign in again."
                )
            }

            result.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )
        }

        return result
    }

    private func perform<T: Decodable>(
        _ request: URLRequest
    ) async throws -> T {
        let (data, response) = try await URLSession.shared.data(
            for: request
        )
        
        if request.url?.path.contains("/orders") == true {
            if let json = String(data: data, encoding: .utf8) {
                print("ORDERS API RESPONSE:")
                print(json)
            }
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let problem = try? JSONDecoder().decode(
                APIProblem.self,
                from: data
            )

            let message = problem?.detail
                ?? problem?.title
                ?? String(data: data, encoding: .utf8)
                ?? "Request failed."

            throw APIError.serverError(
                http.statusCode,
                message
            )
        }

        if data.isEmpty && T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        let decoder = JSONDecoder()

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [
                .withInternetDateTime,
                .withFractionalSeconds
            ]

            if let date = formatter.date(from: value) {
                return date
            }

            formatter.formatOptions = [.withInternetDateTime]

            if let date = formatter.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO 8601 date: \(value)"
            )
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            print("DECODING ERROR: \(error)")
            print(
                "REQUEST URL: \(request.url?.absoluteString ?? "Unknown")"
            )

            if let json = String(data: data, encoding: .utf8) {
                print("SERVER JSON: \(json)")
            }

            throw error
        }
    }

    private func call<T: Decodable>(
        _ path: String,
        method: String = "GET",
        authenticated: Bool = true,
        query: [URLQueryItem] = []
    ) async throws -> T {
        try await perform(
            request(
                path,
                method: method,
                authenticated: authenticated,
                query: query
            )
        )
    }

    private func call<T: Decodable, Body: Encodable>(
        _ path: String,
        method: String,
        body: Body,
        authenticated: Bool = true
    ) async throws -> T {
        var req = try request(
            path,
            method: method,
            authenticated: authenticated
        )

        req.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        req.httpBody = try encoder.encode(body)

        return try await perform(req)
    }

    func register(
        username: String,
        email: String,
        password: String
    ) async throws -> AuthResponse {
        try await call(
            "auth/register",
            method: "POST",
            body: RegisterRequest(
                username: username,
                email: email,
                password: password
            ),
            authenticated: false
        )
    }

    func login(
        email: String,
        password: String
    ) async throws -> AuthResponse {
        try await call(
            "auth/login",
            method: "POST",
            body: LoginRequest(
                email: email,
                password: password
            ),
            authenticated: false
        )
    }

    func getBuffets() async throws -> [Buffet] {
        try await call(
            "buffets",
            authenticated: false
        )
    }

    func getMyBuffets() async throws -> [Buffet] {
        try await call("buffets/mine")
    }

    func getMenu(
        buffetId: UUID,
        date: String? = nil
    ) async throws -> BuffetMenu {
        let query = date.map {
            [URLQueryItem(name: "date", value: $0)]
        } ?? []

        return try await call(
            "buffets/\(buffetId)/menu",
            authenticated: false,
            query: query
        )
    }

    func getSlots(
        buffetId: UUID
    ) async throws -> [PickupSlot] {
        try await call(
            "buffets/\(buffetId)/pickup-slots",
            authenticated: false
        )
    }

    func createOrder(
        slotId: UUID,
        items: [OrderItemRequest]
    ) async throws -> QuickOrder {
        try await call(
            "orders",
            method: "POST",
            body: CreateOrderRequest(
                pickupSlotId: slotId,
                items: items,
                paymentMethod: "PAY_AT_PICKUP"
            )
        )
    }

    func myOrders() async throws -> [QuickOrder] {
        try await call("orders/mine")
    }

    func cancelOrder(
        _ id: UUID
    ) async throws -> QuickOrder {
        try await call(
            "orders/\(id)/cancel",
            method: "POST"
        )
    }

    func staffCancel(
        _ id: UUID
    ) async throws -> QuickOrder {
        try await call(
            "orders/\(id)/staff-cancel",
            method: "POST"
        )
    }

    func buffetOrders(
        _ id: UUID,
        status: String? = nil,
        page: Int = 0
    ) async throws -> OrderPage {
        var query = [
            URLQueryItem(
                name: "page",
                value: String(page)
            ),
            URLQueryItem(
                name: "size",
                value: "30"
            )
        ]

        if let status {
            query.append(
                URLQueryItem(
                    name: "status",
                    value: status
                )
            )
        }

        return try await call(
            "buffets/\(id)/orders",
            query: query
        )
    }

    func updateOrderStatus(
        _ id: UUID,
        status: String
    ) async throws -> QuickOrder {
        try await call(
            "orders/\(id)/status",
            method: "PATCH",
            body: OrderStatusRequest(status: status)
        )
    }

    func notifications() async throws -> [NotificationItem] {
        try await call("notifications")
    }

    func markNotificationRead(
        _ id: UUID
    ) async throws -> NotificationItem {
        try await call(
            "notifications/\(id)/read",
            method: "PATCH"
        )
    }

    func submitFeedback(
        orderId: UUID,
        rating: String,
        comment: String
    ) async throws -> FeedbackItem {
        try await call(
            "orders/\(orderId)/feedback",
            method: "POST",
            body: FeedbackRequest(
                emojiRating: rating,
                comment: comment
            )
        )
    }

    func getFeedback(
        orderId: UUID
    ) async throws -> FeedbackItem {
        try await call(
            "orders/\(orderId)/feedback"
        )
    }

    func buffetFeedback(
        _ id: UUID
    ) async throws -> [FeedbackItem] {
        try await call(
            "buffets/\(id)/feedback"
        )
    }

    func flagFeedback(
        _ id: UUID,
        flagged: Bool
    ) async throws -> FeedbackItem {
        try await call(
            "feedback/\(id)/flag",
            method: "PATCH",
            body: FlagRequest(flagged: flagged)
        )
    }

    func createMeal(
        buffetId: UUID,
        name: String,
        description: String,
        price: Decimal,
        capacity: Int?
    ) async throws -> Meal {
        try await call(
            "buffets/\(buffetId)/meals",
            method: "POST",
            body: CreateMealRequest(
                name: name,
                description: description,
                photoUrl: nil,
                nutritionInfo: [:],
                price: price,
                capacity: capacity
            )
        )
    }

    func updateMeal(
        _ id: UUID,
        name: String,
        description: String,
        price: Decimal,
        capacity: Int?
    ) async throws -> Meal {
        try await call(
            "buffets/meals/\(id)",
            method: "PATCH",
            body: UpdateMealRequest(
                name: name,
                description: description,
                photoUrl: nil,
                price: price,
                capacity: capacity
            )
        )
    }

    func setMealAvailability(
        _ id: UUID,
        available: Bool
    ) async throws -> Meal {
        try await call(
            "buffets/meals/\(id)/availability",
            method: "PATCH",
            body: AvailabilityRequest(available: available)
        )
    }

    func deleteMeal(
        _ id: UUID
    ) async throws {
        let _: EmptyResponse = try await call(
            "buffets/meals/\(id)",
            method: "DELETE"
        )
    }

    func createSlot(
        buffetId: UUID,
        time: Date,
        capacity: Int
    ) async throws -> PickupSlot {
        try await call(
            "buffets/\(buffetId)/pickup-slots",
            method: "POST",
            body: CreateSlotRequest(
                slotTime: time,
                capacity: capacity
            )
        )
    }

    func createStaff(
        username: String,
        email: String,
        password: String
    ) async throws -> StaffResponse {
        try await call(
            "admin/staff",
            method: "POST",
            body: CreateStaffRequest(
                username: username,
                email: email,
                temporaryPassword: password
            )
        )
    }

    func createBuffet(
        name: String,
        location: String,
        ownerId: UUID
    ) async throws -> Buffet {
        try await call(
            "admin/buffets",
            method: "POST",
            body: CreateBuffetRequest(
                name: name,
                location: location,
                ownerId: ownerId
            )
        )
    }

    func setUserActive(
        _ id: UUID,
        active: Bool
    ) async throws -> UserStatusResponse {
        try await call(
            "admin/users/\(id)/active",
            method: "PATCH",
            body: ActiveRequest(active: active)
        )
    }
}


struct DemoPaymentPreviewRequest: Encodable {
    let pickupSlotId: UUID
    let items: [OrderItemRequest]
}

struct DemoPaymentPreviewResponse: Decodable {
    let mode: String
    let status: String
    let message: String
}

extension APIService {

    func previewDemoApplePay(
        slotId: UUID,
        items: [OrderItemRequest]
    ) async throws -> DemoPaymentPreviewResponse {

        guard let token = KeychainManager.readToken() else {
            throw APIError.serverError(
                401,
                "Please sign in again."
            )
        }

        guard let url = URL(
            string: "http://localhost:8080/api/demo-payments/preview"
        ) else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        request.setValue(
            "Bearer \(token)",
            forHTTPHeaderField: "Authorization"
        )

        request.httpBody = try JSONEncoder().encode(
            DemoPaymentPreviewRequest(
                pickupSlotId: slotId,
                items: items
            )
        )

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let message = String(
                data: data,
                encoding: .utf8
            ) ?? "Demo checkout request failed."

            throw APIError.serverError(
                http.statusCode,
                message
            )
        }

        return try JSONDecoder().decode(
            DemoPaymentPreviewResponse.self,
            from: data
        )
    }
}
