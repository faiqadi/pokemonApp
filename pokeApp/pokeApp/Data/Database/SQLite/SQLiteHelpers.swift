// © 2025 Prodia. All rights reserved.

import Foundation
import SQLite3

// SQLite macro compatibility for Swift. Use as the final parameter to sqlite3_bind_text
// to indicate SQLite should make its own copy of the provided C string.
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)


