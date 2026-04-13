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

CREATE TYPE chat_type       AS ENUM ('direct', 'group', 'channel');
CREATE TYPE message_type    AS ENUM ('text', 'media', 'system');
CREATE TYPE media_kind      AS ENUM ('image', 'video', 'audio', 'file');
CREATE TYPE presence_status AS ENUM ('online', 'away', 'offline');
CREATE TYPE delivery_status AS ENUM ('sent', 'delivered', 'read', 'failed');
CREATE TYPE call_type       AS ENUM ('voice', 'video');
CREATE TYPE call_status     AS ENUM ('ringing', 'active', 'ended', 'missed', 'declined');

-- ------------------------------------------------------------
-- Users & profiles
-- ------------------------------------------------------------

CREATE TABLE app_user (
    user_id      BIGSERIAL       PRIMARY KEY,
    username     CITEXT          NOT NULL UNIQUE,
    display_name TEXT,
    email        CITEXT          UNIQUE,
    phone        TEXT            UNIQUE,
    bio          TEXT,
    avatar_url   TEXT,
    avatar_color TEXT            NOT NULL DEFAULT '#4361ee',
    is_online    BOOLEAN         NOT NULL DEFAULT FALSE,
    last_seen_at TIMESTAMPTZ,
    created_at   TIMESTAMPTZ     NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------
-- Contacts
-- ------------------------------------------------------------

CREATE TABLE contact (
    owner_id    BIGINT      NOT NULL REFERENCES app_user (user_id),
    contact_id  BIGINT      NOT NULL REFERENCES app_user (user_id),
    nickname    TEXT,
    is_favorite BOOLEAN     NOT NULL DEFAULT FALSE,
    added_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (owner_id, contact_id),
    CHECK (owner_id <> contact_id)
);

CREATE TABLE blocked_user (
    user_id         BIGINT      NOT NULL REFERENCES app_user (user_id),
    blocked_user_id BIGINT      NOT NULL REFERENCES app_user (user_id),
    blocked_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, blocked_user_id),
    CHECK (user_id <> blocked_user_id)
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
    is_muted  BOOLEAN      NOT NULL DEFAULT FALSE,
    muted_until TIMESTAMPTZ,
    joined_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    PRIMARY KEY (chat_id, user_id)
);

-- ------------------------------------------------------------
-- Messages
-- ------------------------------------------------------------

CREATE TABLE message (
    message_id   BIGSERIAL     PRIMARY KEY,
    chat_id      BIGINT        NOT NULL REFERENCES chat (chat_id),
    sender_id    BIGINT        NOT NULL REFERENCES app_user (user_id),
    mtype        message_type  NOT NULL,
    reply_to_id  BIGINT        REFERENCES message (message_id),
    is_pinned    BOOLEAN       NOT NULL DEFAULT FALSE,
    is_deleted   BOOLEAN       NOT NULL DEFAULT FALSE,
    sent_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    edited_at    TIMESTAMPTZ
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
-- Message delivery tracking
-- ------------------------------------------------------------

CREATE TABLE message_status (
    message_id BIGINT          NOT NULL REFERENCES message (message_id),
    user_id    BIGINT          NOT NULL REFERENCES app_user (user_id),
    status     delivery_status NOT NULL DEFAULT 'sent',
    updated_at TIMESTAMPTZ     NOT NULL DEFAULT now(),
    PRIMARY KEY (message_id, user_id)
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
-- Typing indicators (ephemeral, cleaned up periodically)
-- ------------------------------------------------------------

CREATE TABLE typing_indicator (
    chat_id    BIGINT      NOT NULL REFERENCES chat (chat_id),
    user_id    BIGINT      NOT NULL REFERENCES app_user (user_id),
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (chat_id, user_id)
);

-- ------------------------------------------------------------
-- Calls
-- ------------------------------------------------------------

CREATE TABLE call (
    call_id    BIGSERIAL   PRIMARY KEY,
    chat_id    BIGINT      NOT NULL REFERENCES chat (chat_id),
    started_by BIGINT      NOT NULL REFERENCES app_user (user_id),
    ctype      call_type   NOT NULL,
    status     call_status NOT NULL DEFAULT 'ringing',
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at   TIMESTAMPTZ
);

CREATE TABLE call_participant (
    call_id   BIGINT      NOT NULL REFERENCES call (call_id),
    user_id   BIGINT      NOT NULL REFERENCES app_user (user_id),
    joined_at TIMESTAMPTZ,
    left_at   TIMESTAMPTZ,
    PRIMARY KEY (call_id, user_id)
);

-- ------------------------------------------------------------
-- Indexes
-- ------------------------------------------------------------

CREATE INDEX idx_message_chat_sent    ON message (chat_id, sent_at DESC);
CREATE INDEX idx_message_sender       ON message (sender_id);
CREATE INDEX idx_message_reply        ON message (reply_to_id) WHERE reply_to_id IS NOT NULL;
CREATE INDEX idx_reaction_message     ON reaction (message_id);
CREATE INDEX idx_read_receipt_msg     ON read_receipt (message_id);
CREATE INDEX idx_media_message_media  ON media_message (media_id);
CREATE INDEX idx_contact_owner        ON contact (owner_id);
CREATE INDEX idx_contact_contact      ON contact (contact_id);
CREATE INDEX idx_blocked_user         ON blocked_user (user_id);
CREATE INDEX idx_message_status_msg   ON message_status (message_id);
CREATE INDEX idx_call_chat            ON call (chat_id, started_at DESC);
CREATE INDEX idx_user_last_seen       ON app_user (last_seen_at DESC) WHERE last_seen_at IS NOT NULL;

COMMIT;
