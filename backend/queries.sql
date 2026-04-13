-- ============================================================
-- Chat Application – Common Queries
-- ============================================================

-- 1. List all chats for a given user with last message preview
SELECT c.chat_id,
       c.ctype,
       COALESCE(c.title, partner.display_name)  AS chat_name,
       last_msg.body                             AS last_message,
       last_msg.sent_at                          AS last_activity
FROM   chat_participant cp
JOIN   chat c ON c.chat_id = cp.chat_id
LEFT JOIN LATERAL (
    SELECT m.message_id, tm.body, m.sent_at
    FROM   message m
    LEFT JOIN text_message tm ON tm.message_id = m.message_id
    WHERE  m.chat_id = c.chat_id
    ORDER  BY m.sent_at DESC
    LIMIT  1
) last_msg ON TRUE
LEFT JOIN LATERAL (
    SELECT au.display_name
    FROM   chat_participant cp2
    JOIN   app_user au ON au.user_id = cp2.user_id
    WHERE  cp2.chat_id = c.chat_id
      AND  cp2.user_id <> cp.user_id
      AND  c.ctype = 'direct'
    LIMIT 1
) partner ON TRUE
WHERE  cp.user_id = 1  -- :current_user_id
ORDER  BY last_msg.sent_at DESC NULLS LAST;


-- 2. Fetch paginated messages for a chat
SELECT m.message_id,
       m.mtype,
       m.sent_at,
       m.edited_at,
       m.reply_to_id,
       m.is_pinned,
       au.display_name   AS sender_name,
       tm.body           AS text_body,
       sm.event_type     AS system_event,
       sm.payload        AS system_payload,
       med.url           AS media_url,
       med.kind          AS media_kind
FROM   message m
JOIN   app_user au        ON au.user_id    = m.sender_id
LEFT JOIN text_message tm ON tm.message_id = m.message_id
LEFT JOIN system_message sm ON sm.message_id = m.message_id
LEFT JOIN media_message mm ON mm.message_id = m.message_id
LEFT JOIN media med        ON med.media_id  = mm.media_id
WHERE  m.chat_id = 2  -- :chat_id
  AND  m.is_deleted = FALSE
ORDER  BY m.sent_at ASC
LIMIT  50
OFFSET 0;  -- :page_offset


-- 3. Unread message count per chat for a user
SELECT cp.chat_id,
       COUNT(m.message_id) AS unread_count
FROM   chat_participant cp
JOIN   message m ON m.chat_id = cp.chat_id
                AND m.sent_at > cp.joined_at
                AND m.sender_id <> cp.user_id
LEFT JOIN read_receipt rr ON rr.message_id = m.message_id
                          AND rr.user_id   = cp.user_id
WHERE  cp.user_id = 1  -- :current_user_id
  AND  rr.message_id IS NULL
GROUP  BY cp.chat_id;


-- 4. Reactions summary for a message
SELECT r.emoji,
       COUNT(*)                        AS count,
       array_agg(au.display_name)      AS reacted_by
FROM   reaction r
JOIN   app_user au ON au.user_id = r.user_id
WHERE  r.message_id = 4  -- :message_id
GROUP  BY r.emoji
ORDER  BY count DESC;


-- 5. Search messages by text across all chats a user belongs to
SELECT m.message_id,
       c.chat_id,
       COALESCE(c.title, 'Direct Message') AS chat_name,
       au.display_name                     AS sender,
       tm.body,
       m.sent_at
FROM   chat_participant cp
JOIN   message m       ON m.chat_id    = cp.chat_id
JOIN   text_message tm ON tm.message_id = m.message_id
JOIN   app_user au     ON au.user_id   = m.sender_id
JOIN   chat c          ON c.chat_id    = cp.chat_id
WHERE  cp.user_id = 1  -- :current_user_id
  AND  tm.body ILIKE '%design%'  -- :search_term
ORDER  BY m.sent_at DESC
LIMIT  20;


-- 6. Insert a new text message (typical send flow)
WITH new_msg AS (
    INSERT INTO message (chat_id, sender_id, mtype)
    VALUES (1, 1, 'text')  -- :chat_id, :sender_id
    RETURNING message_id
)
INSERT INTO text_message (message_id, body)
SELECT message_id, 'Hello everyone!'  -- :body
FROM   new_msg
RETURNING message_id;


-- 7. Mark messages as read up to a point
INSERT INTO read_receipt (message_id, user_id)
SELECT m.message_id, 1  -- :current_user_id
FROM   message m
WHERE  m.chat_id = 2    -- :chat_id
  AND  m.sent_at <= now()
  AND  m.sender_id <> 1 -- :current_user_id
ON CONFLICT (message_id, user_id) DO NOTHING;


-- ============================================================
-- Contact queries
-- ============================================================

-- 8. Fetch all contacts for a user (sorted by display name)
SELECT au.user_id,
       au.display_name,
       au.username,
       au.phone,
       au.avatar_color,
       au.is_online,
       au.last_seen_at,
       c.nickname,
       c.is_favorite
FROM   contact c
JOIN   app_user au ON au.user_id = c.contact_id
WHERE  c.owner_id = 1  -- :current_user_id
ORDER  BY c.is_favorite DESC, au.display_name ASC;


-- 9. Search contacts by name, username, or phone
SELECT au.user_id,
       au.display_name,
       au.username,
       au.phone,
       au.avatar_color,
       au.is_online,
       au.last_seen_at
FROM   contact c
JOIN   app_user au ON au.user_id = c.contact_id
WHERE  c.owner_id = 1  -- :current_user_id
  AND  (au.display_name ILIKE '%bob%'   -- :search_term
        OR au.username ILIKE '%bob%'
        OR au.phone LIKE '%bob%')
ORDER  BY au.display_name ASC;


-- 10. Find or create a direct chat with a contact
SELECT c.chat_id
FROM   chat c
JOIN   chat_participant cp1 ON cp1.chat_id = c.chat_id AND cp1.user_id = 1  -- :current_user_id
JOIN   chat_participant cp2 ON cp2.chat_id = c.chat_id AND cp2.user_id = 2  -- :contact_user_id
WHERE  c.ctype = 'direct';

-- If no result, create one:
-- INSERT INTO chat (ctype, created_by) VALUES ('direct', 1) RETURNING chat_id;
-- INSERT INTO chat_participant (chat_id, user_id, role) VALUES (:new_id, 1, 'member'), (:new_id, 2, 'member');


-- 11. Online contacts
SELECT au.user_id, au.display_name, au.avatar_color
FROM   contact c
JOIN   app_user au ON au.user_id = c.contact_id
WHERE  c.owner_id = 1  -- :current_user_id
  AND  au.is_online = TRUE
ORDER  BY au.display_name ASC;
