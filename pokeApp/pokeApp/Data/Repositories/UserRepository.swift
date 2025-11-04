// © 2025 Prodia. All rights reserved.

import Foundation
import SQLite3
import CryptoKit

protocol UserRepository {
    func register(name: String, email: String, password: String) throws -> User
    func login(email: String, password: String) throws -> User
    func getCurrentUser() -> User?
    func logout()
}

enum UserRepositoryError: Error, LocalizedError {
    case emailAlreadyUsed
    case invalidCredentials
    case unknown

    var errorDescription: String? {
        switch self {
        case .emailAlreadyUsed: return "Email sudah terpakai."
        case .invalidCredentials: return "Email atau kata sandi salah."
        case .unknown: return "Terjadi kesalahan. Coba lagi."
        }
    }
}

final class SQLiteUserRepository: UserRepository {
    private let db = SQLiteManager.shared
    private let userDefaultsKey = "current_user_id"

    func register(name: String, email: String, password: String) throws -> User {
        guard getUserByEmail(email) == nil else { throw UserRepositoryError.emailAlreadyUsed }
        let sql = "INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?);"
        let passwordHash = Self.sha256(password)
        let success = db.execute(sql: sql) { stmt in
            sqlite3_bind_text(stmt, 1, (name as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 2, (email as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 3, (passwordHash as NSString).utf8String, -1, SQLITE_TRANSIENT)
        }
        if success, let user = getUserByEmail(email) {
            setCurrentUserId(user.id)
            return user
        }
        throw UserRepositoryError.unknown
    }

    func login(email: String, password: String) throws -> User {
        let passwordHash = Self.sha256(password)
        let sql = "SELECT id, name, email FROM users WHERE email = ? AND password_hash = ? LIMIT 1;"
        var foundUser: User?
        db.query(sql: sql, bindings: { stmt in
            sqlite3_bind_text(stmt, 1, (email as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 2, (passwordHash as NSString).utf8String, -1, SQLITE_TRANSIENT)
        }, row: { stmt in
            let id = sqlite3_column_int64(stmt, 0)
            let name = String(cString: sqlite3_column_text(stmt, 1))
            let emailVal = String(cString: sqlite3_column_text(stmt, 2))
            foundUser = User(id: id, name: name, email: emailVal)
        })
        guard let user = foundUser else { throw UserRepositoryError.invalidCredentials }
        setCurrentUserId(user.id)
        return user
    }

    func getCurrentUser() -> User? {
        let id = UserDefaults.standard.object(forKey: userDefaultsKey) as? Int64 ?? 0
        guard id > 0 else { return nil }
        return getUserById(id)
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    private func getUserByEmail(_ email: String) -> User? {
        let sql = "SELECT id, name, email FROM users WHERE email = ? LIMIT 1;"
        var result: User?
        db.query(sql: sql, bindings: { stmt in
            sqlite3_bind_text(stmt, 1, (email as NSString).utf8String, -1, SQLITE_TRANSIENT)
        }, row: { stmt in
            let id = sqlite3_column_int64(stmt, 0)
            let name = String(cString: sqlite3_column_text(stmt, 1))
            let emailVal = String(cString: sqlite3_column_text(stmt, 2))
            result = User(id: id, name: name, email: emailVal)
        })
        return result
    }

    private func getUserById(_ id: Int64) -> User? {
        let sql = "SELECT id, name, email FROM users WHERE id = ? LIMIT 1;"
        var result: User?
        db.query(sql: sql, bindings: { stmt in
            sqlite3_bind_int64(stmt, 1, id)
        }, row: { stmt in
            let idVal = sqlite3_column_int64(stmt, 0)
            let name = String(cString: sqlite3_column_text(stmt, 1))
            let email = String(cString: sqlite3_column_text(stmt, 2))
            result = User(id: idVal, name: name, email: email)
        })
        return result
    }

    private func setCurrentUserId(_ id: Int64) {
        UserDefaults.standard.set(id, forKey: userDefaultsKey)
    }

    private static func sha256(_ string: String) -> String {
        guard let data = string.data(using: .utf8) else { return string }
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}


