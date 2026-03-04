# Search

## Overview

Full-text search across all notes using PostgreSQL's `tsvector` FTS and `pg_trgm` trigram matching. Hybrid ranking blends FTS relevance (70%) with trigram similarity (30%). Results include highlighted snippets and link to the note's channel.

**Files**:
- `memoka_server/lib/src/search/search_setup.dart` (DB infrastructure: table, indexes, trigger)
- `memoka_server/lib/src/search/search_endpoint.dart` (search + context-loading endpoints)
- `memoka_server/lib/src/search/search_result.spy.yaml` (SearchResult protocol model)
- `memoka_server/lib/server.dart` (startup call to `SearchSetup.ensureSearchInfrastructure`)
- `memoka_flutter/lib/providers/global_search_provider.dart` (search state)
- `memoka_flutter/lib/providers/search_results_provider.dart` (result fetching)
- `memoka_flutter/lib/providers/recent_searches_provider.dart` (search history)
- `memoka_flutter/lib/widgets/search_bar_widget.dart` (search input UI)
- `memoka_flutter/lib/widgets/search_results.dart` (results list UI)

---

## Serverpod Schema Constraint

Serverpod 3.3.1's `verifyDatabaseIntegrity()` compares the live DB against the target schema (derived from `.spy.yaml` models and migrations). **In development mode, any mismatch is fatal** (`ExitException(1)`). In production/staging, it only warns.

This means:

1. **No `tsvector` column type** in spy.yaml. Supported types: `bool`, `int`, `double`, `String`, `DateTime`, `Duration`, `ByteData`, `UuidValue`, `Uri`, `BigInt`, plus vector types (`Vector`, `HalfVector`, `SparseVector`, `Bit`). A `tsvector` column on a tracked table would map to `ColumnType.unknown` and fail validation.

2. **No GIN operator classes** in spy.yaml indexes. `type: gin` is supported, but without operator classes (e.g., `gin_trgm_ops`). A bare `USING GIN (text_column)` actually fails in PostgreSQL because `text` has no default GIN operator class. [Issue #4650](https://github.com/serverpod/serverpod/issues/4650) tracks this; [PR #4658](https://github.com/serverpod/serverpod/pull/4658) (not merged) attempts to add `gin_trgm_ops` support.

3. **Extra columns/indexes on tracked tables are fatal**. The validator iterates live DB columns/indexes for each tracked table. Anything present in the DB but missing from the target schema triggers a mismatch. There is no allow-list or ignore mechanism. [Issue #4743](https://github.com/serverpod/serverpod/issues/4743) requests this.

### Untracked Table Pattern

Tables with no `.spy.yaml` definition are invisible to the schema validator. The validator only iterates `getTargetTableDefinitions()` — tables it knows about. This is how `app_settings` and `note_search` avoid validation: they are created via raw SQL at startup and have no spy.yaml.

This is the recommended pattern for any PostgreSQL feature that Serverpod's type system can't represent (tsvector, custom GIN indexes, CHECK constraints, etc.). Trade-off: no ORM support — all queries use `session.db.unsafeQuery()`.

If [Issue #4743](https://github.com/serverpod/serverpod/issues/4743) (schema validation allow-list) or [PR #4658](https://github.com/serverpod/serverpod/pull/4658) (GIN trigram support) are merged in a future Serverpod version, the search column and indexes could potentially move back onto the `notes` table.

---

## Data Model

### SearchResult (protocol model, non-table)

| Field         | Type       | Description                                          |
|---------------|------------|------------------------------------------------------|
| `noteId`      | `int`      | The matching note's ID                               |
| `channelId`   | `int`      | Channel the note belongs to                          |
| `channelName` | `String`   | Channel name (for display)                           |
| `channelEmoji`| `String`   | Channel emoji (for display)                          |
| `snippet`     | `String`   | Content excerpt with `<b>` tags on matching terms    |
| `createdAt`   | `DateTime` | When the note was created                            |
| `score`       | `double`   | Relevance score (higher = better)                    |

### note_search (database table, untracked)

Created at server startup by `SearchSetup.ensureSearchInfrastructure()`. Not in any `.spy.yaml` — invisible to Serverpod's schema validator.

| Column          | Type       | Description                                       |
|-----------------|------------|---------------------------------------------------|
| `note_id`       | `bigint`   | PK, FK → `notes(id)` ON DELETE CASCADE            |
| `search_vector` | `tsvector` | Pre-computed FTS vector (`'simple'` config)        |

**Indexes**:
- `note_search_vector_idx`: GIN index on `search_vector`

**Trigger**: `notes_search_trigger` fires `AFTER INSERT OR UPDATE OF content ON notes`. Upserts into `note_search` with `to_tsvector('simple', COALESCE(NEW.content, ''))`.

**Extensions**: `pg_trgm` (enabled at setup for the `similarity()` function).

---

## Server: Search Setup

`SearchSetup.ensureSearchInfrastructure(Session session)` — called once at server startup from `server.dart`. Idempotent: checks if `note_search` table exists, returns immediately if so.

On first run:
1. Enables `pg_trgm` extension
2. Creates `note_search` table with `note_id bigint PRIMARY KEY` and `search_vector tsvector`
3. Creates GIN index on `search_vector`
4. Backfills existing notes via `INSERT ... SELECT`
5. Creates trigger function + trigger on `notes.content`

---

## Server: Search Endpoint

### searchNotes(session, query, {limit = 20})

Hybrid FTS prefix + unanchored subsequence search. Returns ranked `List<SearchResult>`.

### Matching Rules

Given notes: 1) "Quick", 2) "Quick Brown", 3) "Quick Brown Fox":

| Query | Matches | Why |
|-------|---------|-----|
| `Q` | 1,2,3 | Prefix match on "Quick" |
| `Quick` | 1,2,3 | Exact word match |
| `Qck` | 1,2,3 | Subsequence Q→c→k in "Quick" |
| `ick` | 1,2,3 | Unanchored subsequence i→c→k in "Quick" |
| `uick` | 1,2,3 | Unanchored subsequence u→i→c→k in "Quick" |
| `Brown` | 2,3 | Exact word match |
| `Brwn` | 2,3 | Subsequence B→r→w→n in "Brown" |
| `Fox` | 3 | Exact word match |
| `Quick Fox` | 1,2,3 | OR logic: matches "Quick" OR "Fox" (note 3 scores highest — matches both) |
| `QuickBrown` | None | Single token checked per-word; no single word matches that subsequence |

**Core rules**:
- **Case insensitive**: "quick" matches "Quick"
- **Unanchored subsequence**: query chars must appear in order within a content word, but can start at any position — "ick" matches "Quick"
- **Per-word matching**: each query token is checked against individual content words, cannot span across words — "QuickBrown" matches no single word
- **OR logic**: multi-word queries match notes containing ANY query term; notes matching more terms score higher
- **Non-alphanumeric = word boundary**: content split on `[^a-zA-Z0-9]+`, so punctuation and markdown syntax (`**bold**`, `[text](url)`) are stripped naturally
- **No minimum query length**: even single characters trigger search
- **Ranking**: score DESC (FTS rank * 0.7 + subsequence bonus 0.3), then createdAt DESC as tiebreaker

**Algorithm**:
1. Trim and truncate query to 200 chars, split into words
2. **FTS CTE**: prefix match `word1:* | word2:*` via GIN-indexed `search_vector`, ranked by `ts_rank()`
3. **Subsequence CTE**: split content on `[^a-zA-Z0-9]+`, check each content word against unanchored subsequence regex per query word (OR)
4. **Combine**: LEFT JOIN both CTEs, score = `fts.rank * 0.7 + (subseq ? 0.3 : 0.0)`
5. **Snippet**: `ts_headline()` with `<b>` tags for FTS matches; falls back to first 100 chars if no FTS terms
6. Order by score DESC, createdAt DESC; limit

**Filters**: excludes archived notes, tombstoned notes, archived channels, tombstoned channels.

### getNotesAroundId(session, channelId, noteId, {limit = 25})

Loads notes surrounding a specific note for jump-to-context. Returns ~`limit` notes: half before, half after the target (by `createdAt`), including the target itself. Uses `NoteQuery.findWithAttachments` for consistent attachment loading.

---

## Related Files

| File | Purpose |
|------|---------|
| `memoka_server/lib/src/search/search_setup.dart` | DB infrastructure (table, index, trigger) |
| `memoka_server/lib/src/search/search_endpoint.dart` | Search + context-loading API |
| `memoka_server/lib/src/search/search_result.spy.yaml` | SearchResult protocol model |
| `memoka_server/lib/server.dart` | Startup call to `ensureSearchInfrastructure` |
| `memoka_flutter/lib/providers/global_search_provider.dart` | Search state management |
| `memoka_flutter/lib/providers/search_results_provider.dart` | Result fetching provider |
| `memoka_flutter/lib/providers/recent_searches_provider.dart` | Search history |
| `memoka_flutter/lib/widgets/search_bar_widget.dart` | Search input UI |
| `memoka_flutter/lib/widgets/search_results.dart` | Results list UI |
