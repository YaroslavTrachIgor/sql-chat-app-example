-- ============================================================
-- Chat Application – SQLite Schema (iOS)
-- ============================================================

CREATE TABLE IF NOT EXISTS app_user (
    user_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    username     TEXT    NOT NULL UNIQUE COLLATE NOCASE,
    display_name TEXT,
    email        TEXT    UNIQUE COLLATE NOCASE,
    phone        TEXT    UNIQUE,
    bio          TEXT,
    avatar_url   TEXT,
    avatar_color TEXT    NOT NULL DEFAULT '#4361ee',
    is_online    INTEGER NOT NULL DEFAULT 0,
    last_seen_at TEXT,
    created_at   TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS contact (
    owner_id    INTEGER NOT NULL REFERENCES app_user(user_id),
    contact_id  INTEGER NOT NULL REFERENCES app_user(user_id),
    nickname    TEXT,
    is_favorite INTEGER NOT NULL DEFAULT 0,
    added_at    TEXT    NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (owner_id, contact_id),
    CHECK (owner_id <> contact_id)
);

CREATE TABLE IF NOT EXISTS blocked_user (
    user_id         INTEGER NOT NULL REFERENCES app_user(user_id),
    blocked_user_id INTEGER NOT NULL REFERENCES app_user(user_id),
    blocked_at      TEXT    NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (user_id, blocked_user_id),
    CHECK (user_id <> blocked_user_id)
);

CREATE TABLE IF NOT EXISTS chat (
    chat_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    ctype      TEXT    NOT NULL CHECK (ctype IN ('direct','group','channel')),
    title      TEXT,
    created_by INTEGER REFERENCES app_user(user_id),
    created_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS chat_participant (
    chat_id     INTEGER NOT NULL REFERENCES chat(chat_id),
    user_id     INTEGER NOT NULL REFERENCES app_user(user_id),
    role        TEXT,
    is_muted    INTEGER NOT NULL DEFAULT 0,
    muted_until TEXT,
    joined_at   TEXT    NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (chat_id, user_id)
);

CREATE TABLE IF NOT EXISTS message (
    message_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    chat_id     INTEGER NOT NULL REFERENCES chat(chat_id),
    sender_id   INTEGER NOT NULL REFERENCES app_user(user_id),
    mtype       TEXT    NOT NULL CHECK (mtype IN ('text','media','system')),
    reply_to_id INTEGER REFERENCES message(message_id),
    is_pinned   INTEGER NOT NULL DEFAULT 0,
    is_deleted  INTEGER NOT NULL DEFAULT 0,
    sent_at     TEXT    NOT NULL DEFAULT (datetime('now')),
    edited_at   TEXT
);

CREATE TABLE IF NOT EXISTS text_message (
    message_id INTEGER PRIMARY KEY REFERENCES message(message_id),
    body       TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS system_message (
    message_id INTEGER PRIMARY KEY REFERENCES message(message_id),
    event_type TEXT    NOT NULL,
    payload    TEXT
);

CREATE TABLE IF NOT EXISTS message_status (
    message_id INTEGER NOT NULL REFERENCES message(message_id),
    user_id    INTEGER NOT NULL REFERENCES app_user(user_id),
    status     TEXT    NOT NULL DEFAULT 'sent' CHECK (status IN ('sent','delivered','read','failed')),
    updated_at TEXT    NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (message_id, user_id)
);

CREATE TABLE IF NOT EXISTS media (
    media_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    kind        TEXT    NOT NULL CHECK (kind IN ('image','video','audio','file')),
    mime_type   TEXT,
    bytes       INTEGER,
    url         TEXT,
    uploaded_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS media_message (
    message_id INTEGER PRIMARY KEY REFERENCES message(message_id),
    media_id   INTEGER NOT NULL REFERENCES media(media_id)
);

CREATE TABLE IF NOT EXISTS image_media (
    media_id INTEGER PRIMARY KEY REFERENCES media(media_id),
    width    INTEGER,
    height   INTEGER
);

CREATE TABLE IF NOT EXISTS video_media (
    media_id    INTEGER PRIMARY KEY REFERENCES media(media_id),
    width       INTEGER,
    height      INTEGER,
    duration_ms INTEGER
);

CREATE TABLE IF NOT EXISTS audio_media (
    media_id    INTEGER PRIMARY KEY REFERENCES media(media_id),
    duration_ms INTEGER
);

CREATE TABLE IF NOT EXISTS file_media (
    media_id  INTEGER PRIMARY KEY REFERENCES media(media_id),
    file_name TEXT
);

CREATE TABLE IF NOT EXISTS reaction (
    message_id INTEGER NOT NULL REFERENCES message(message_id),
    user_id    INTEGER NOT NULL REFERENCES app_user(user_id),
    emoji      TEXT    NOT NULL,
    reacted_at TEXT    NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (message_id, user_id, emoji)
);

CREATE TABLE IF NOT EXISTS read_receipt (
    message_id INTEGER NOT NULL REFERENCES message(message_id),
    user_id    INTEGER NOT NULL REFERENCES app_user(user_id),
    read_at    TEXT    NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (message_id, user_id)
);

CREATE TABLE IF NOT EXISTS typing_indicator (
    chat_id    INTEGER NOT NULL REFERENCES chat(chat_id),
    user_id    INTEGER NOT NULL REFERENCES app_user(user_id),
    started_at TEXT    NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (chat_id, user_id)
);

CREATE TABLE IF NOT EXISTS call (
    call_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    chat_id    INTEGER NOT NULL REFERENCES chat(chat_id),
    started_by INTEGER NOT NULL REFERENCES app_user(user_id),
    ctype      TEXT    NOT NULL CHECK (ctype IN ('voice','video')),
    status     TEXT    NOT NULL DEFAULT 'ringing' CHECK (status IN ('ringing','active','ended','missed','declined')),
    started_at TEXT    NOT NULL DEFAULT (datetime('now')),
    ended_at   TEXT
);

CREATE TABLE IF NOT EXISTS call_participant (
    call_id   INTEGER NOT NULL REFERENCES call(call_id),
    user_id   INTEGER NOT NULL REFERENCES app_user(user_id),
    joined_at TEXT,
    left_at   TEXT,
    PRIMARY KEY (call_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_message_chat_sent   ON message(chat_id, sent_at);
CREATE INDEX IF NOT EXISTS idx_message_sender      ON message(sender_id);
CREATE INDEX IF NOT EXISTS idx_reaction_message    ON reaction(message_id);
CREATE INDEX IF NOT EXISTS idx_read_receipt_msg    ON read_receipt(message_id);
CREATE INDEX IF NOT EXISTS idx_media_message_media ON media_message(media_id);
CREATE INDEX IF NOT EXISTS idx_contact_owner       ON contact(owner_id);
CREATE INDEX IF NOT EXISTS idx_call_chat           ON call(chat_id, started_at);
