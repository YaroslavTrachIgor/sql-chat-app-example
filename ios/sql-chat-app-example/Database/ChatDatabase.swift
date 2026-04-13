import Foundation
import SQLite3

final class ChatDatabase {
    static let shared = ChatDatabase()

    private var db: OpaquePointer?

    private init() {
        let path = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("chat.sqlite")
            .path

        // Remove old DB to pick up schema changes during development
        try? FileManager.default.removeItem(atPath: path)

        guard sqlite3_open(path, &db) == SQLITE_OK else {
            fatalError("Unable to open database at \(path)")
        }
        sqlite3_exec(db, "PRAGMA journal_mode=WAL;", nil, nil, nil)
        sqlite3_exec(db, "PRAGMA foreign_keys=ON;", nil, nil, nil)
        createTables()
        seedIfNeeded()
    }

    deinit { sqlite3_close(db) }

    // MARK: - Schema

    private func createTables() {
        guard let url = Bundle.main.url(forResource: "schema", withExtension: "sql"),
              let sql = try? String(contentsOf: url, encoding: .utf8) else {
            fatalError("schema.sql not found in bundle")
        }
        exec(sql)
    }

    private func seedIfNeeded() {
        let count = queryScalar("SELECT COUNT(*) FROM app_user")
        guard count == 0 else { return }
        exec("""
            INSERT INTO app_user (username, display_name, email, phone, bio, avatar_color, is_online, last_seen_at) VALUES
              ('alice','Alice Johnson','alice@example.com','+1-555-0101','Product designer','#4361ee',1,datetime('now')),
              ('bob','Bob Smith','bob@example.com','+1-555-0102','Frontend engineer','#e74c3c',0,datetime('now','-15 minutes')),
              ('charlie','Charlie Lee','charlie@example.com','+1-555-0103','Backend developer','#2ecc71',0,datetime('now','-2 hours')),
              ('diana','Diana Ruiz','diana@example.com','+1-555-0104','QA lead','#9b59b6',1,datetime('now')),
              ('elena','Elena Petrova','elena@example.com','+1-555-0105','DevOps engineer','#e67e22',0,datetime('now','-1 day')),
              ('frank','Frank Torres','frank@example.com','+1-555-0106','Mobile developer','#1abc9c',0,datetime('now','-3 days')),
              ('grace','Grace Kim','grace@example.com','+1-555-0107','Data scientist','#f39c12',1,datetime('now')),
              ('henry','Henry Wang','henry@example.com','+1-555-0108','Security engineer','#3498db',0,datetime('now','-5 hours')),
              ('isabella','Isabella Costa','isabella@example.com','+1-555-0109','UX researcher','#e91e63',0,datetime('now','-30 minutes')),
              ('james','James Murphy','james@example.com','+1-555-0110','Tech lead','#ff5722',0,datetime('now','-12 hours')),
              ('katya','Katya Novak','katya@example.com','+1-555-0111','Project manager','#8bc34a',1,datetime('now')),
              ('lucas','Lucas Andersen','lucas@example.com','+1-555-0112','Fullstack dev','#00bcd4',0,datetime('now','-4 days'));

            INSERT INTO contact (owner_id, contact_id, nickname, is_favorite) VALUES
              (1,2,NULL,1),(1,3,NULL,0),(1,4,NULL,1),
              (1,5,'Lena',0),(1,6,NULL,0),(1,7,NULL,1),
              (1,8,NULL,0),(1,9,'Isa',0),(1,10,NULL,0),
              (1,11,NULL,0),(1,12,NULL,0);

            INSERT INTO chat (ctype, title, created_by) VALUES
              ('direct', NULL, 1),
              ('group', 'Project Alpha', 1),
              ('direct', NULL, 1);

            INSERT INTO chat_participant (chat_id, user_id, role, joined_at) VALUES
              (1,1,'member',datetime('now')),
              (1,2,'member',datetime('now')),
              (2,1,'admin',datetime('now')),
              (2,2,'member',datetime('now')),
              (2,3,'member',datetime('now')),
              (2,4,'member',datetime('now')),
              (3,1,'member',datetime('now')),
              (3,3,'member',datetime('now'));

            INSERT INTO message (chat_id, sender_id, mtype, sent_at) VALUES
              (1,1,'text',datetime('now','-2 hours')),
              (1,2,'text',datetime('now','-115 minutes')),
              (1,1,'text',datetime('now','-110 minutes')),
              (2,1,'text',datetime('now','-30 minutes')),
              (2,3,'text',datetime('now','-28 minutes')),
              (2,2,'media',datetime('now','-25 minutes')),
              (2,1,'system',datetime('now','-20 minutes')),
              (3,3,'text',datetime('now','-5 minutes'));

            INSERT INTO text_message (message_id, body) VALUES
              (1,'Hey Bob! How is the design coming along?'),
              (2,'Almost done — just finalising the color palette.'),
              (3,'Nice, send me a screenshot when you can.'),
              (4,'Team standup: what is everyone working on today?'),
              (5,'Finishing up the API integration tests.'),
              (8,'Hey Alice, want to review the PR together?');

            INSERT INTO media (kind, mime_type, bytes, url) VALUES
              ('image','image/png',204800,'https://cdn.example.com/mockup-v3.png');
            INSERT INTO media_message (message_id, media_id) VALUES (6,1);
            INSERT INTO image_media (media_id, width, height) VALUES (1,1920,1080);

            INSERT INTO system_message (message_id, event_type, payload) VALUES
              (7,'member_joined','{"user_id":4,"display_name":"Diana Ruiz"}');

            INSERT INTO reaction (message_id, user_id, emoji) VALUES
              (1,2,'👍'),(4,2,'🔥'),(4,3,'👋'),(5,1,'💯');

            INSERT INTO read_receipt (message_id, user_id) VALUES
              (1,2),(2,1),(3,2),(4,2),(4,3),(4,4);
        """)
    }

    // MARK: - Chat list

    struct ChatListItem {
        let chatId: Int64
        let name: String
        let lastMessage: String?
        let lastActivity: String?
        let ctype: String
    }

    func fetchChatList(userId: Int64) -> [ChatListItem] {
        let sql = """
            SELECT c.chat_id, c.ctype,
                   CASE WHEN c.ctype='direct' THEN
                     (SELECT au.display_name FROM chat_participant cp2
                      JOIN app_user au ON au.user_id=cp2.user_id
                      WHERE cp2.chat_id=c.chat_id AND cp2.user_id<>?1 LIMIT 1)
                   ELSE c.title END AS chat_name,
                   (SELECT tm.body FROM message m2
                    LEFT JOIN text_message tm ON tm.message_id=m2.message_id
                    WHERE m2.chat_id=c.chat_id ORDER BY m2.sent_at DESC LIMIT 1
                   ) AS last_message,
                   (SELECT m3.sent_at FROM message m3
                    WHERE m3.chat_id=c.chat_id ORDER BY m3.sent_at DESC LIMIT 1
                   ) AS last_activity
            FROM chat_participant cp
            JOIN chat c ON c.chat_id=cp.chat_id
            WHERE cp.user_id=?1
            ORDER BY last_activity DESC
        """
        var items: [ChatListItem] = []
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return items }
        sqlite3_bind_int64(stmt, 1, userId)
        while sqlite3_step(stmt) == SQLITE_ROW {
            items.append(ChatListItem(
                chatId:       sqlite3_column_int64(stmt, 0),
                name:         string(stmt, 2) ?? "Chat",
                lastMessage:  string(stmt, 3),
                lastActivity: string(stmt, 4),
                ctype:        string(stmt, 1) ?? "direct"
            ))
        }
        sqlite3_finalize(stmt)
        return items
    }

    // MARK: - Contacts

    struct ContactRow {
        let userId: Int64
        let displayName: String
        let username: String
        let phone: String?
        let avatarColor: String
        let isOnline: Bool
        let lastSeenAt: String?
        let nickname: String?
        let isFavorite: Bool
    }

    func fetchContacts(userId: Int64) -> [ContactRow] {
        let sql = """
            SELECT au.user_id, au.display_name, au.username, au.phone,
                   au.avatar_color, au.is_online, au.last_seen_at,
                   c.nickname, c.is_favorite
            FROM contact c
            JOIN app_user au ON au.user_id = c.contact_id
            WHERE c.owner_id = ?
            ORDER BY c.is_favorite DESC, au.display_name ASC
        """
        var rows: [ContactRow] = []
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return rows }
        sqlite3_bind_int64(stmt, 1, userId)
        while sqlite3_step(stmt) == SQLITE_ROW {
            rows.append(ContactRow(
                userId:      sqlite3_column_int64(stmt, 0),
                displayName: string(stmt, 1) ?? "",
                username:    string(stmt, 2) ?? "",
                phone:       string(stmt, 3),
                avatarColor: string(stmt, 4) ?? "#4361ee",
                isOnline:    sqlite3_column_int(stmt, 5) != 0,
                lastSeenAt:  string(stmt, 6),
                nickname:    string(stmt, 7),
                isFavorite:  sqlite3_column_int(stmt, 8) != 0
            ))
        }
        sqlite3_finalize(stmt)
        return rows
    }

    func searchContacts(userId: Int64, query: String) -> [ContactRow] {
        let sql = """
            SELECT au.user_id, au.display_name, au.username, au.phone,
                   au.avatar_color, au.is_online, au.last_seen_at,
                   c.nickname, c.is_favorite
            FROM contact c
            JOIN app_user au ON au.user_id = c.contact_id
            WHERE c.owner_id = ?1
              AND (au.display_name LIKE '%' || ?2 || '%'
                   OR au.username LIKE '%' || ?2 || '%'
                   OR c.nickname LIKE '%' || ?2 || '%')
            ORDER BY au.display_name ASC
        """
        var rows: [ContactRow] = []
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return rows }
        sqlite3_bind_int64(stmt, 1, userId)
        sqlite3_bind_text(stmt, 2, (query as NSString).utf8String, -1, nil)
        while sqlite3_step(stmt) == SQLITE_ROW {
            rows.append(ContactRow(
                userId:      sqlite3_column_int64(stmt, 0),
                displayName: string(stmt, 1) ?? "",
                username:    string(stmt, 2) ?? "",
                phone:       string(stmt, 3),
                avatarColor: string(stmt, 4) ?? "#4361ee",
                isOnline:    sqlite3_column_int(stmt, 5) != 0,
                lastSeenAt:  string(stmt, 6),
                nickname:    string(stmt, 7),
                isFavorite:  sqlite3_column_int(stmt, 8) != 0
            ))
        }
        sqlite3_finalize(stmt)
        return rows
    }

    // MARK: - Find or create direct chat

    func findOrCreateDirectChat(currentUserId: Int64, contactUserId: Int64) -> Int64 {
        let findSQL = """
            SELECT c.chat_id
            FROM chat c
            JOIN chat_participant cp1 ON cp1.chat_id=c.chat_id AND cp1.user_id=?1
            JOIN chat_participant cp2 ON cp2.chat_id=c.chat_id AND cp2.user_id=?2
            WHERE c.ctype='direct'
            LIMIT 1
        """
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, findSQL, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, currentUserId)
            sqlite3_bind_int64(stmt, 2, contactUserId)
            if sqlite3_step(stmt) == SQLITE_ROW {
                let chatId = sqlite3_column_int64(stmt, 0)
                sqlite3_finalize(stmt)
                return chatId
            }
            sqlite3_finalize(stmt)
        }

        exec("INSERT INTO chat (ctype, created_by) VALUES ('direct', \(currentUserId))")
        let chatId = queryScalar("SELECT last_insert_rowid()")
        exec("""
            INSERT INTO chat_participant (chat_id, user_id, role) VALUES
              (\(chatId), \(currentUserId), 'member'),
              (\(chatId), \(contactUserId), 'member')
        """)
        return chatId
    }

    // MARK: - Messages

    struct MessageRow {
        let messageId: Int64
        let senderId: Int64
        let senderName: String
        let mtype: String
        let sentAt: String
        let body: String?
        let eventType: String?
        let payload: String?
        let mediaUrl: String?
        let mediaKind: String?
    }

    func fetchMessages(chatId: Int64) -> [MessageRow] {
        let sql = """
            SELECT m.message_id, m.sender_id, au.display_name, m.mtype, m.sent_at,
                   tm.body, sm.event_type, sm.payload, med.url, med.kind
            FROM message m
            JOIN app_user au ON au.user_id=m.sender_id
            LEFT JOIN text_message tm   ON tm.message_id=m.message_id
            LEFT JOIN system_message sm ON sm.message_id=m.message_id
            LEFT JOIN media_message mm  ON mm.message_id=m.message_id
            LEFT JOIN media med         ON med.media_id=mm.media_id
            WHERE m.chat_id=? AND m.is_deleted=0
            ORDER BY m.sent_at ASC
        """
        var rows: [MessageRow] = []
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return rows }
        sqlite3_bind_int64(stmt, 1, chatId)
        while sqlite3_step(stmt) == SQLITE_ROW {
            rows.append(MessageRow(
                messageId:  sqlite3_column_int64(stmt, 0),
                senderId:   sqlite3_column_int64(stmt, 1),
                senderName: string(stmt, 2) ?? "",
                mtype:      string(stmt, 3) ?? "text",
                sentAt:     string(stmt, 4) ?? "",
                body:       string(stmt, 5),
                eventType:  string(stmt, 6),
                payload:    string(stmt, 7),
                mediaUrl:   string(stmt, 8),
                mediaKind:  string(stmt, 9)
            ))
        }
        sqlite3_finalize(stmt)
        return rows
    }

    // MARK: - Search chats

    func searchChats(userId: Int64, query: String) -> [ChatListItem] {
        let sql = """
            SELECT c.chat_id, c.ctype,
                   CASE WHEN c.ctype='direct' THEN
                     (SELECT au.display_name FROM chat_participant cp2
                      JOIN app_user au ON au.user_id=cp2.user_id
                      WHERE cp2.chat_id=c.chat_id AND cp2.user_id<>?1 LIMIT 1)
                   ELSE c.title END AS chat_name,
                   (SELECT tm.body FROM message m2
                    LEFT JOIN text_message tm ON tm.message_id=m2.message_id
                    WHERE m2.chat_id=c.chat_id ORDER BY m2.sent_at DESC LIMIT 1
                   ) AS last_message,
                   (SELECT m3.sent_at FROM message m3
                    WHERE m3.chat_id=c.chat_id ORDER BY m3.sent_at DESC LIMIT 1
                   ) AS last_activity
            FROM chat_participant cp
            JOIN chat c ON c.chat_id=cp.chat_id
            WHERE cp.user_id=?1
              AND chat_name LIKE '%' || ?2 || '%'
            ORDER BY last_activity DESC
        """
        var items: [ChatListItem] = []
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return items }
        sqlite3_bind_int64(stmt, 1, userId)
        sqlite3_bind_text(stmt, 2, (query as NSString).utf8String, -1, nil)
        while sqlite3_step(stmt) == SQLITE_ROW {
            items.append(ChatListItem(
                chatId:       sqlite3_column_int64(stmt, 0),
                name:         string(stmt, 2) ?? "Chat",
                lastMessage:  string(stmt, 3),
                lastActivity: string(stmt, 4),
                ctype:        string(stmt, 1) ?? "direct"
            ))
        }
        sqlite3_finalize(stmt)
        return items
    }

    // MARK: - Reactions

    struct ReactionSummary {
        let emoji: String
        let count: Int
    }

    func fetchReactions(messageId: Int64) -> [ReactionSummary] {
        let sql = "SELECT emoji, COUNT(*) FROM reaction WHERE message_id=? GROUP BY emoji"
        var out: [ReactionSummary] = []
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return out }
        sqlite3_bind_int64(stmt, 1, messageId)
        while sqlite3_step(stmt) == SQLITE_ROW {
            out.append(ReactionSummary(
                emoji: string(stmt, 0) ?? "",
                count: Int(sqlite3_column_int(stmt, 1))
            ))
        }
        sqlite3_finalize(stmt)
        return out
    }

    // MARK: - Send message

    func sendTextMessage(chatId: Int64, senderId: Int64, body: String) {
        exec("INSERT INTO message (chat_id, sender_id, mtype) VALUES (\(chatId), \(senderId), 'text')")
        let msgId = queryScalar("SELECT last_insert_rowid()")
        var stmt: OpaquePointer?
        let sql = "INSERT INTO text_message (message_id, body) VALUES (?, ?)"
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, Int64(msgId))
            sqlite3_bind_text(stmt, 2, (body as NSString).utf8String, -1, nil)
            sqlite3_step(stmt)
            sqlite3_finalize(stmt)
        }
    }

    // MARK: - Chat info

    func chatName(chatId: Int64, currentUserId: Int64) -> String {
        let sql = """
            SELECT CASE WHEN c.ctype='direct' THEN
              (SELECT au.display_name FROM chat_participant cp2
               JOIN app_user au ON au.user_id=cp2.user_id
               WHERE cp2.chat_id=c.chat_id AND cp2.user_id<>?1 LIMIT 1)
            ELSE c.title END
            FROM chat c WHERE c.chat_id=?2
        """
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return "Chat" }
        sqlite3_bind_int64(stmt, 1, currentUserId)
        sqlite3_bind_int64(stmt, 2, chatId)
        return sqlite3_step(stmt) == SQLITE_ROW ? (string(stmt, 0) ?? "Chat") : "Chat"
    }

    func participantCount(chatId: Int64) -> Int {
        let sql = "SELECT COUNT(*) FROM chat_participant WHERE chat_id=?"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        sqlite3_bind_int64(stmt, 1, chatId)
        return sqlite3_step(stmt) == SQLITE_ROW ? Int(sqlite3_column_int(stmt, 0)) : 0
    }

    // MARK: - Helpers

    private func exec(_ sql: String) {
        var err: UnsafeMutablePointer<CChar>?
        sqlite3_exec(db, sql, nil, nil, &err)
        if let err { debugPrint("SQL error:", String(cString: err)); sqlite3_free(err) }
    }

    private func queryScalar(_ sql: String) -> Int64 {
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK,
              sqlite3_step(stmt) == SQLITE_ROW else { return 0 }
        return sqlite3_column_int64(stmt, 0)
    }

    private func string(_ stmt: OpaquePointer?, _ col: Int32) -> String? {
        guard let ptr = sqlite3_column_text(stmt, col) else { return nil }
        return String(cString: ptr)
    }
}
