-- ============================================================
-- Chat Application – Sample seed data
-- ============================================================
-- Run AFTER schema.sql
-- ============================================================

BEGIN;

-- Users (expanded roster for contacts demo)
INSERT INTO app_user (username, display_name, email, phone, bio, avatar_color, is_online, last_seen_at) VALUES
    ('alice',     'Alice Johnson',   'alice@example.com',   '+1-555-0101', 'Product designer',           '#4361ee', TRUE,  now()),
    ('bob',       'Bob Smith',       'bob@example.com',     '+1-555-0102', 'Frontend engineer',          '#e74c3c', FALSE, now() - INTERVAL '15 minutes'),
    ('charlie',   'Charlie Lee',     'charlie@example.com', '+1-555-0103', 'Backend developer',          '#2ecc71', FALSE, now() - INTERVAL '2 hours'),
    ('diana',     'Diana Ruiz',      'diana@example.com',   '+1-555-0104', 'QA lead',                    '#9b59b6', TRUE,  now()),
    ('elena',     'Elena Petrova',   'elena@example.com',   '+1-555-0105', 'DevOps engineer',            '#e67e22', FALSE, now() - INTERVAL '1 day'),
    ('frank',     'Frank Torres',    'frank@example.com',   '+1-555-0106', 'Mobile developer',           '#1abc9c', FALSE, now() - INTERVAL '3 days'),
    ('grace',     'Grace Kim',       'grace@example.com',   '+1-555-0107', 'Data scientist',             '#f39c12', TRUE,  now()),
    ('henry',     'Henry Wang',      'henry@example.com',   '+1-555-0108', 'Security engineer',          '#3498db', FALSE, now() - INTERVAL '5 hours'),
    ('isabella',  'Isabella Costa',  'isabella@example.com','+1-555-0109', 'UX researcher',              '#e91e63', FALSE, now() - INTERVAL '30 minutes'),
    ('james',     'James Murphy',    'james@example.com',   '+1-555-0110', 'Tech lead',                  '#ff5722', FALSE, now() - INTERVAL '12 hours'),
    ('katya',     'Katya Novak',     'katya@example.com',   '+1-555-0111', 'Project manager',            '#8bc34a', TRUE,  now()),
    ('lucas',     'Lucas Andersen',  'lucas@example.com',   '+1-555-0112', 'Fullstack dev',              '#00bcd4', FALSE, now() - INTERVAL '4 days');

-- Alice's contacts (user_id = 1)
INSERT INTO contact (owner_id, contact_id, nickname, is_favorite) VALUES
    (1, 2,  NULL,        TRUE),
    (1, 3,  NULL,        FALSE),
    (1, 4,  NULL,        TRUE),
    (1, 5,  'Lena',      FALSE),
    (1, 6,  NULL,        FALSE),
    (1, 7,  NULL,        TRUE),
    (1, 8,  NULL,        FALSE),
    (1, 9,  'Isa',       FALSE),
    (1, 10, NULL,        FALSE),
    (1, 11, NULL,        FALSE),
    (1, 12, NULL,        FALSE);

-- Mutual contacts
INSERT INTO contact (owner_id, contact_id) VALUES
    (2, 1), (3, 1), (4, 1), (5, 1), (7, 1),
    (2, 3), (3, 4), (4, 5);

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

-- Direct chat between Alice and Charlie
INSERT INTO chat (ctype, title, created_by) VALUES
    ('direct', NULL, 1);

INSERT INTO chat_participant (chat_id, user_id, role) VALUES
    (3, 1, 'member'),
    (3, 3, 'member');

-- Messages in direct chat (Alice <-> Bob)
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

-- Direct chat (Alice <-> Charlie) messages
INSERT INTO message (chat_id, sender_id, mtype, sent_at) VALUES
    (3, 3, 'text', now() - INTERVAL '5 minutes');

INSERT INTO text_message (message_id, body) VALUES
    (8, 'Hey Alice, want to review the PR together?');

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

-- Message delivery statuses
INSERT INTO message_status (message_id, user_id, status) VALUES
    (1, 2, 'read'),
    (2, 1, 'read'),
    (3, 2, 'read'),
    (4, 2, 'read'),
    (4, 3, 'read'),
    (5, 1, 'read'),
    (8, 1, 'delivered');

-- A sample call
INSERT INTO call (chat_id, started_by, ctype, status, started_at, ended_at) VALUES
    (1, 2, 'voice', 'ended', now() - INTERVAL '3 hours', now() - INTERVAL '2 hours 45 minutes');

INSERT INTO call_participant (call_id, user_id, joined_at, left_at) VALUES
    (1, 2, now() - INTERVAL '3 hours', now() - INTERVAL '2 hours 45 minutes'),
    (1, 1, now() - INTERVAL '2 hours 59 minutes', now() - INTERVAL '2 hours 45 minutes');

COMMIT;
