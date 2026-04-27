<div align="center">

# Chatting App SQL Schema Project (Activity 5)

**A relational chat schema with matching Web and iOS clients, plus a PostgreSQL reference implementation.**

[![Swift](https://img.shields.io/badge/Swift-5.9+-F05138?style=flat&logo=swift&logoColor=white)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-iOS%2017+-007ACC?style=flat&logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![SQLite](https://img.shields.io/badge/SQLite-3-003B57?style=flat&logo=sqlite&logoColor=white)](https://www.sqlite.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-DDL-4169E1?style=flat&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![JavaScript](https://img.shields.io/badge/JavaScript-ES6+-F7DF1E?style=flat&logo=javascript&logoColor=black)](https://developer.mozilla.org/docs/Web/JavaScript)
[![sql.js](https://img.shields.io/badge/sql.js-WASM-000000?style=flat)](https://sql.js.org/)
[![HTML5](https://img.shields.io/badge/HTML5-client-E34F26?style=flat&logo=html5&logoColor=white)](https://developer.mozilla.org/docs/Web/HTML)

</div>

---

## Overview

This repository models a full-featured chat domain in SQL and ships **three surfaces** that all speak the same relational model: a **browser client** (SQLite in-memory via sql.js) for testing quries and previewing database tables, an **iOS app** (SwiftUI + SQLite), and a **backend** folder with PostgreSQL-oriented DDL, seeds, and example queries. PostgreSQL and SQLite differ only in dialect details (enums vs `CHECK` constraints, and the like).

**Clients include** chat threads, messages (text / media / system), reactions, read receipts, **contacts** with search and add-contact flows (Web and iOS), and a shared visual language (dark theme, list + detail layout, bubble styling).

---

## Repository structure

```
.
├── backend/            # PostgreSQL reference (pure SQL)
│   ├── schema.sql      # DDL – tables, types, indexes
│   ├── seed.sql        # Sample data
│   └── queries.sql     # Common query patterns
│
├── web/                # Browser client (sql.js / WASM)
│   └── index.html      # Single-file UI + SQL console
│
├── ios/                # Xcode project (SwiftUI + SQLite, MVVM)
│   ├── sql-chat-app-example/
│   │   ├── Database/
│   │   │   ├── schema.sql
│   │   │   └── ChatDatabase.swift
│   │   ├── Models/
│   │   │   └── ChatModels.swift
│   │   ├── Services/
│   │   │   └── ChatDatabaseServing.swift
│   │   ├── ViewModels/
│   │   │   └── … (chats, contacts, search, detail, add contact)
│   │   └── Views/
│   │       └── … (tabs, lists, sheets, chat detail)
│   └── sql-chat-app-example.xcodeproj/
│
└── docs/
    └── erd.png         # Schema diagram
```

---

## Schema overview

| Table | Purpose |
| --- | --- |
| `app_user` | Registered users (username, display name, email) |
| `contact` | User-to-user contact relationships |
| `blocked_user` | Blocking between users |
| `chat` | Conversation container — direct, group, or channel |
| `chat_participant` | Many-to-many link between users and chats |
| `message` | Base message row with type discriminator (`text`, `media`, `system`) |
| `text_message` | Body text for text messages |
| `system_message` | Event type + JSON payload for system events |
| `message_status` | Delivery / read-style status per message |
| `media` | Uploaded file metadata (kind, mime, size, URL) |
| `media_message` | Links a message to its media |
| `image_media` | Width / height for images |
| `video_media` | Width / height / duration for videos |
| `audio_media` | Duration for audio clips |
| `file_media` | Original filename for generic files |
| `reaction` | Emoji reactions on messages |
| `read_receipt` | Per-user read tracking |
| `typing_indicator` | Ephemeral typing state |
| `call` | Voice/video call records |
| `call_participant` | Participants in a call |

PostgreSQL uses custom enum types where noted in `backend/schema.sql` (`chat_type`, `message_type`, `media_kind`, etc.). SQLite mirrors the same invariants with `CHECK` constraints in `ios/sql-chat-app-example/Database/schema.sql`.

---

## Quick start

### Web (no server required)

```bash
open web/index.html
# or double-click the file in Finder
```

The page loads **sql.js**, creates tables in memory, seeds data, and exposes a **SQL console** for ad hoc queries.

### iOS

1. Open `ios/sql-chat-app-example.xcodeproj` in Xcode 15+.
2. Build and run on a simulator or device (iOS 17+).
3. On first launch the app creates a local SQLite database with the same conceptual seed data.

> **Note:** Ensure `schema.sql` is in the app target’s **Copy Bundle Resources** build phase if it is not already.

**Run unit tests from the terminal** (adjust the simulator name to one installed on your Mac):

```bash
cd ios
xcodebuild test -scheme sql-chat-app-example \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:sql-chat-app-exampleTests
```

List simulators: `xcrun simctl list devices available`.

### Backend (PostgreSQL)

```bash
createdb chatapp
psql chatapp -f backend/schema.sql
psql chatapp -f backend/seed.sql
psql chatapp -f backend/queries.sql
```

## DataGrip project setup

Use JetBrains DataGrip against a database where you applied `backend/schema.sql`:

1. **New project** → name e.g. `sql-chat-app`.
2. **Add data source** → PostgreSQL → connect to `chatapp` (or your instance).
3. **Attach** the `backend/` folder for navigation and SQL assistance.
4. Optional: run `schema.sql`, `seed.sql`, and `queries.sql` from the editor.
5. To share: zip the DataGrip project folder, or keep `.idea` under `backend/` (commit shared settings; exclude credential-bearing `dataSources.local.xml`).

---

## Contributors

Primary authors:

- **Yaroslav Trach**
- **Ryan Soroka**

---

<p align="center">
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-6e7681?style=flat-square" alt="MIT License" /></a>
</p>

<p align="center">
  <sub><span style="color:#6e7681;">Licensed under the MIT License. This repository is provided for learning and reference. Submitting this work as your own, or otherwise misrepresenting authorship, constitutes <strong>academic dishonesty</strong> and is not acceptable use of this material.</span></sub>
</p>
