//
//  SessionManager.swift
//  QuickBites
//
//  Created by Karakat Tursynbayeva on 11/5/26.
//
import Foundation
import Combine

@MainActor
final class SessionManager: ObservableObject {
    @Published private(set) var user: AuthUser?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var errorMessage: String?

    init() {
        // A stored token alone is not proof of an active session.
        // The user signs in again until a validated restore endpoint is available.
        isAuthenticated = false
    }

    func finishAuthentication(_ response: AuthResponse) {
        guard response.expiresAt > Date() else {
            errorMessage = "Your session has already expired."
            return
        }
        guard KeychainManager.saveToken(response.accessToken) else {
            errorMessage = "Unable to save the session securely."
            return
        }
        errorMessage = nil
        user = response.user
        isAuthenticated = true
    }

    func signOut() {
        KeychainManager.deleteToken()
        user = nil
        isAuthenticated = false
        errorMessage = nil
    }
}
