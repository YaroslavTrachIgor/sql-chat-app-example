-- ============================================================
-- Chat Application – PostgreSQL Schema
-- ============================================================
-- Requires: PostgreSQL 14+ with citext extension
-- ============================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS citext;

-- ------------------------------------------------------------
-- Enum types
-- ------------------------------------------------------------

CREATE TYPE chat_type    AS ENUM ('direct', 'group', 'channel');
CREATE TYPE message_type AS ENUM ('text', 'media', 'system');
CREATE TYPE media_kind   AS ENUM ('image', 'video', 'audio', 'file');

-- ------------------------------------------------------------
-- Users
-- ------------------------------------------------------------

CREATE TABLE app_user (
    user_id      BIGSERIAL    PRIMARY KEY,
    username     CITEXT       NOT NULL UNIQUE,
    display_name TEXT,
    email        CITEXT       UNIQUE,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------
-- Chats
-- ------------------------------------------------------------

CREATE TABLE chat (
    chat_id    BIGSERIAL    PRIMARY KEY,
    ctype      chat_type    NOT NULL,
    title      TEXT,
    created_by BIGINT       REFERENCES app_user (user_id),
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE chat_participant (
    chat_id   BIGINT       NOT NULL REFERENCES chat (chat_id),
    user_id   BIGINT       NOT NULL REFERENCES app_user (user_id),
    role      TEXT,
    joined_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    PRIMARY KEY (chat_id, user_id)
);

-- ------------------------------------------------------------
-- Messages
-- ------------------------------------------------------------

CREATE TABLE message (
    message_id BIGSERIAL     PRIMARY KEY,
    chat_id    BIGINT        NOT NULL REFERENCES chat (chat_id),
    sender_id  BIGINT        NOT NULL REFERENCES app_user (user_id),
    mtype      message_type  NOT NULL,
    sent_at    TIMESTAMPTZ   NOT NULL DEFAULT now(),
    edited_at  TIMESTAMPTZ
);

CREATE TABLE text_message (
    message_id BIGINT PRIMARY KEY REFERENCES message (message_id),
    body       TEXT   NOT NULL
);

CREATE TABLE system_message (
    message_id BIGINT PRIMARY KEY REFERENCES message (message_id),
    event_type TEXT   NOT NULL,
    payload    JSONB
);

-- ------------------------------------------------------------
-- Media
-- ------------------------------------------------------------

CREATE TABLE media (
    media_id    BIGSERIAL    PRIMARY KEY,
    kind        media_kind   NOT NULL,
    mime_type   TEXT,
    bytes       BIGINT,
    url         TEXT,
    uploaded_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE media_message (
    message_id BIGINT PRIMARY KEY REFERENCES message (message_id),
    media_id   BIGINT NOT NULL REFERENCES media (media_id)
);

CREATE TABLE image_media (
    media_id BIGINT PRIMARY KEY REFERENCES media (media_id),
    width    INT,
    height   INT
);

CREATE TABLE video_media (
    media_id    BIGINT PRIMARY KEY REFERENCES media (media_id),
    width       INT,
    height      INT,
    duration_ms INT
);

CREATE TABLE audio_media (
    media_id    BIGINT PRIMARY KEY REFERENCES media (media_id),
    duration_ms INT
);

CREATE TABLE file_media (
    media_id  BIGINT PRIMARY KEY REFERENCES media (media_id),
    file_name TEXT
);

-- ------------------------------------------------------------
-- Reactions & read receipts
-- ------------------------------------------------------------

CREATE TABLE reaction (
    message_id BIGINT      NOT NULL REFERENCES message (message_id),
    user_id    BIGINT      NOT NULL REFERENCES app_user (user_id),
    emoji      TEXT        NOT NULL,
    reacted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (message_id, user_id, emoji)
);

CREATE TABLE read_receipt (
    message_id BIGINT      NOT NULL REFERENCES message (message_id),
    user_id    BIGINT      NOT NULL REFERENCES app_user (user_id),
    read_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (message_id, user_id)
);

-- ------------------------------------------------------------
-- Indexes
-- ------------------------------------------------------------

CREATE INDEX idx_message_chat_sent   ON message (chat_id, sent_at DESC);
CREATE INDEX idx_message_sender      ON message (sender_id);
CREATE INDEX idx_reaction_message    ON reaction (message_id);
CREATE INDEX idx_read_receipt_msg    ON read_receipt (message_id);
CREATE INDEX idx_media_message_media ON media_message (media_id);

COMMIT;
