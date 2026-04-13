-- ============================================================
-- Chat Application – Sample seed data
-- ============================================================
-- Run AFTER schema.sql
-- ============================================================

BEGIN;

-- Users
INSERT INTO app_user (username, display_name, email) VALUES
    ('alice',   'Alice Johnson',  'alice@example.com'),
    ('bob',     'Bob Smith',      'bob@example.com'),
    ('charlie', 'Charlie Lee',    'charlie@example.com'),
    ('diana',   'Diana Ruiz',     'diana@example.com');

-- Direct chat between Alice and Bob
INSERT INTO chat (ctype, title, created_by) VALUES
    ('direct', NULL, 1);

INSERT INTO chat_participant (chat_id, user_id, role) VALUES
    (1, 1, 'member'),
    (1, 2, 'member');

-- Group chat
INSERT INTO chat (ctype, title, created_by) VALUES
    ('group', 'Project Alpha', 1);

INSERT INTO chat_participant (chat_id, user_id, role) VALUES
    (2, 1, 'admin'),
    (2, 2, 'member'),
    (2, 3, 'member'),
    (2, 4, 'member');

-- Messages in direct chat
INSERT INTO message (chat_id, sender_id, mtype, sent_at) VALUES
    (1, 1, 'text', now() - INTERVAL '2 hours'),
    (1, 2, 'text', now() - INTERVAL '1 hour 55 minutes'),
    (1, 1, 'text', now() - INTERVAL '1 hour 50 minutes');

INSERT INTO text_message (message_id, body) VALUES
    (1, 'Hey Bob! How is the design coming along?'),
    (2, 'Almost done — just finalising the color palette.'),
    (3, 'Nice, send me a screenshot when you can.');

-- Messages in group chat
INSERT INTO message (chat_id, sender_id, mtype, sent_at) VALUES
    (2, 1, 'text',   now() - INTERVAL '30 minutes'),
    (2, 3, 'text',   now() - INTERVAL '28 minutes'),
    (2, 2, 'media',  now() - INTERVAL '25 minutes'),
    (2, 1, 'system', now() - INTERVAL '20 minutes');

INSERT INTO text_message (message_id, body) VALUES
    (4, 'Team standup: what is everyone working on today?'),
    (5, 'Finishing up the API integration tests.');

-- Media message (an image)
INSERT INTO media (kind, mime_type, bytes, url) VALUES
    ('image', 'image/png', 204800, 'https://cdn.example.com/uploads/mockup-v3.png');

INSERT INTO media_message (message_id, media_id) VALUES (6, 1);

INSERT INTO image_media (media_id, width, height) VALUES (1, 1920, 1080);

-- System message
INSERT INTO system_message (message_id, event_type, payload) VALUES
    (7, 'member_joined', '{"user_id": 4, "display_name": "Diana Ruiz"}');

-- Reactions
INSERT INTO reaction (message_id, user_id, emoji) VALUES
    (1, 2, '👍'),
    (4, 2, '🔥'),
    (4, 3, '👋'),
    (5, 1, '💯');

-- Read receipts
INSERT INTO read_receipt (message_id, user_id) VALUES
    (1, 2),
    (2, 1),
    (3, 2),
    (4, 2),
    (4, 3),
    (4, 4);

COMMIT;
