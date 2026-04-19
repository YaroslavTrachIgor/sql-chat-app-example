-- ============================================================
-- Chat Application - PostgreSQL Schema
-- ============================================================
-- Requires: PostgreSQL 14+ with citext extension
--
-- This schema is designed as a relational graph:
-- 1) app_user is the root identity table.
-- 2) chat + chat_participant model conversation membership.
-- 3) message is the core content table.
-- 4) specialized tables (text_message, media_message, etc.) extend message/media rows.
-- 5) engagement tables (reaction, read_receipt, message_status) reference message and app_user.
--
-- Foreign keys intentionally enforce creation order:
-- parents must exist before children can be inserted.
-- ============================================================

BEGIN;

-- CITEXT gives case-insensitive uniqueness for username/email.
-- Effect: "Alice" and "alice" are treated as duplicates for uniqueness checks.
CREATE EXTENSION IF NOT EXISTS citext;

-- ------------------------------------------------------------
-- Enum types (domain constraints)
-- ------------------------------------------------------------
-- These enums constrain valid values and make intent explicit.
-- They are reused across multiple tables.
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
-- app_user is the foundational entity:
-- nearly every other table references app_user(user_id).
-- Deleting a user row will fail if dependent rows still exist
-- (because FK actions are not set to CASCADE in this schema).
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
-- contact is a directed relationship:
-- owner_id -> the user who owns the contact list
-- contact_id -> the person appearing in that list
-- Effect on reads: contact joins to app_user to render contact cards.
CREATE TABLE contact (
    owner_id    BIGINT      NOT NULL REFERENCES app_user (user_id),
    contact_id  BIGINT      NOT NULL REFERENCES app_user (user_id),
    nickname    TEXT,
    is_favorite BOOLEAN     NOT NULL DEFAULT FALSE,
    added_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (owner_id, contact_id),
    CHECK (owner_id <> contact_id)
);

-- blocked_user is also directed:
-- user_id blocks blocked_user_id.
-- Effect: business logic should filter blocked users from chat/contact surfaces.
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
-- chat is the conversation container.
-- created_by references app_user and records who started the chat.
-- For direct chats, title is often NULL and computed from participants at query time.
CREATE TABLE chat (
    chat_id    BIGSERIAL    PRIMARY KEY,
    ctype      chat_type    NOT NULL,
    title      TEXT,
    created_by BIGINT       REFERENCES app_user (user_id),
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- chat_participant is a many-to-many bridge between chat and app_user.
-- Each row means "this user belongs to this chat".
-- Downstream effects:
-- - message visibility is typically scoped to chat participants.
-- - unread counts use this table as the per-user chat membership source.
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
-- message is the canonical message header row.
-- It references:
-- - chat(chat_id): which conversation the message belongs to
-- - app_user(user_id): who sent it
-- - message(message_id): optional self-reference for reply threading
-- Effects:
-- - deleting a chat/user/message requires handling dependent children first.
-- - child content tables rely on this row existing first.
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

-- text_message extends message 1:1 for textual payloads.
-- FK + PK on message_id guarantees one text payload per message max.
CREATE TABLE text_message (
    message_id BIGINT PRIMARY KEY REFERENCES message (message_id),
    body       TEXT   NOT NULL
);

-- system_message extends message 1:1 for event/system payloads.
-- payload can hold structured event metadata as JSONB.
CREATE TABLE system_message (
    message_id BIGINT PRIMARY KEY REFERENCES message (message_id),
    event_type TEXT   NOT NULL,
    payload    JSONB
);

-- ------------------------------------------------------------
-- Message delivery tracking
-- ------------------------------------------------------------
-- message_status tracks per-user delivery state for each message.
-- Composite PK prevents duplicate status rows per (message,user).
-- Effect: updates here drive "sent/delivered/read" indicators in clients.
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
-- media stores shared file metadata independent of any specific message.
-- message linkage happens through media_message.
CREATE TABLE media (
    media_id    BIGSERIAL    PRIMARY KEY,
    kind        media_kind   NOT NULL,
    mime_type   TEXT,
    bytes       BIGINT,
    url         TEXT,
    uploaded_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- media_message is a 1:1 extension from message -> media.
-- message_id as PK means one media attachment record per message in this model.
CREATE TABLE media_message (
    message_id BIGINT PRIMARY KEY REFERENCES message (message_id),
    media_id   BIGINT NOT NULL REFERENCES media (media_id)
);

-- The following tables are type-specific media extensions.
-- Each is 1:1 with media(media_id), and should align with media.kind.
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
-- reaction: many users can react to many messages with many emoji values.
-- PK(message_id, user_id, emoji) allows multiple emojis per user/message pair
-- but prevents duplicate same-emoji reactions by the same user.
CREATE TABLE reaction (
    message_id BIGINT      NOT NULL REFERENCES message (message_id),
    user_id    BIGINT      NOT NULL REFERENCES app_user (user_id),
    emoji      TEXT        NOT NULL,
    reacted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (message_id, user_id, emoji)
);

-- read_receipt: at most one "read" marker per (message,user).
-- Effect: unread counters are usually computed by anti-joining this table.
CREATE TABLE read_receipt (
    message_id BIGINT      NOT NULL REFERENCES message (message_id),
    user_id    BIGINT      NOT NULL REFERENCES app_user (user_id),
    read_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (message_id, user_id)
);

-- ------------------------------------------------------------
-- Typing indicators (ephemeral, cleaned up periodically)
-- ------------------------------------------------------------
-- typing_indicator is intentionally lightweight and transient.
-- One row per (chat,user) means "currently typing" state.
CREATE TABLE typing_indicator (
    chat_id    BIGINT      NOT NULL REFERENCES chat (chat_id),
    user_id    BIGINT      NOT NULL REFERENCES app_user (user_id),
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (chat_id, user_id)
);

-- ------------------------------------------------------------
-- Calls
-- ------------------------------------------------------------
-- call references the chat where the call occurred and who started it.
-- call_participant tracks who joined that call and for how long.
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
-- These indexes support common access paths and relationship traversals:
-- - by chat timeline
-- - by sender
-- - by FK columns used in joins
-- - by partial conditions where relevant
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
