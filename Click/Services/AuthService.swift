import Foundation
import FirebaseAuth
import Combine

final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = true

    private var authStateListener: AuthStateDidChangeListenerHandle?

    private init() {
        setupAuthStateListener()
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = user != nil
                self?.isLoading = false
            }
        }
    }

    var uid: String? {
        currentUser?.uid
    }

    func signInAnonymously() async throws {
        let result = try await Auth.auth().signInAnonymously()
        await MainActor.run {
            self.currentUser = result.user
            self.isAuthenticated = true
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
        isAuthenticated = false
    }

    func ensureAuthenticated() async throws {
        if currentUser != nil { return }
        try await signInAnonymously()
    }

    func deleteAccount() async throws {
        guard let user = currentUser else { return }
        try await user.delete()
        currentUser = nil
        isAuthenticated = false
    }

    func linkWithApple(credential: AuthCredential) async throws {
        guard let user = currentUser else {
            throw AuthError.notAuthenticated
        }
        let result = try await user.link(with: credential)
        await MainActor.run {
            self.currentUser = result.user
        }
    }
}

enum AuthError: LocalizedError {
    case notAuthenticated
    case linkFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .linkFailed:
            return "Failed to link account"
        }
    }
}
