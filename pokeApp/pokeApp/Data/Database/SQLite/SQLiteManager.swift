// © 2025 Prodia. All rights reserved.

import Foundation
import SQLite3

final class SQLiteManager {
    static let shared = SQLiteManager()

    private let dbURL: URL
    private var db: OpaquePointer?

    private init(fileName: String = "pokeapp.sqlite") {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let baseURL = urls.first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        dbURL = baseURL.appendingPathComponent(fileName)
        openDatabase()
        createTablesIfNeeded()
    }

    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }

    private func openDatabase() {
        if sqlite3_open(dbURL.path, &db) != SQLITE_OK {
            db = nil
        }
    }

    private func createTablesIfNeeded() {
        let createUserTable = """
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL
        );
        """
        _ = execute(sql: createUserTable)
    }

    @discardableResult
    func execute(sql: String, bindings: ((OpaquePointer?) -> Void)? = nil) -> Bool {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return false }
        if let bindings = bindings { bindings(statement) }
        defer { sqlite3_finalize(statement) }
        return sqlite3_step(statement) == SQLITE_DONE
    }

    func query(sql: String, bindings: ((OpaquePointer?) -> Void)? = nil, row: (OpaquePointer?) -> Void) {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return }
        if let bindings = bindings { bindings(statement) }
        defer { sqlite3_finalize(statement) }
        while sqlite3_step(statement) == SQLITE_ROW {
            row(statement)
        }
    }
}


