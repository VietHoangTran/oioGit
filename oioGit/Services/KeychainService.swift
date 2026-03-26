import Foundation
import Security

enum KeychainError: LocalizedError {
    case duplicateItem
    case notFound
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .duplicateItem: return "Keychain item already exists"
        case .notFound: return "Keychain item not found"
        case .unexpectedStatus(let status): return "Keychain error: \(status)"
        }
    }
}

enum KeychainService {

    static func save(token: String) throws {
        guard let data = token.data(using: .utf8) else { return }

        // Delete existing item first to avoid duplicates
        if exists() { try delete() }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainConstants.service,
            kSecAttrAccount as String: KeychainConstants.account,
            kSecValueData as String: data,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    static func retrieve() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainConstants.service,
            kSecAttrAccount as String: KeychainConstants.account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return token
    }

    static func delete() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainConstants.service,
            kSecAttrAccount as String: KeychainConstants.account,
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    static func exists() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainConstants.service,
            kSecAttrAccount as String: KeychainConstants.account,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    /// Returns masked token like "ghp_...xxxx" for display
    static func maskedToken() -> String? {
        guard let token = retrieve() else { return nil }
        let prefix = String(token.prefix(4))
        let suffix = String(token.suffix(4))
        return "\(prefix)...\(suffix)"
    }
}
