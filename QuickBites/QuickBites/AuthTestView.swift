
import SwiftUI

struct AuthTestView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var result = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            Text("QuickBites API Test")
                .font(.title)
                .bold()

            TextField("Username", text: $username)
                .textFieldStyle(.roundedBorder)

            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            Button("Register") {
                Task {
                    await register()
                }
            }
            .disabled(isLoading)

            Button("Login") {
                Task {
                    await login()
                }
            }
            .disabled(isLoading)

            Text(result)
                .font(.footnote)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    @MainActor
    private func register() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await APIService.shared.register(
                username: username,
                email: email,
                password: password
            )

            result = "Registered: \(response.user.username)"
        } catch {
            result = error.localizedDescription
        }
    }

    @MainActor
    private func login() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await APIService.shared.login(
                email: email,
                password: password
            )

            result = "Logged in: \(response.user.username)"
        } catch {
            result = error.localizedDescription
        }
    }
}

#Preview {
    AuthTestView()
}
