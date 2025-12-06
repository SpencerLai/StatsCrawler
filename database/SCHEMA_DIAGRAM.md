# Database Schema Diagram

## Entity Relationship Overview

```
┌─────────────────┐
│     VENUES      │
│ (Dimension)     │
│                 │
│ • venue_id (PK) │
│ • uuid (UNIQUE) │
│ • venue_name    │
│ • city          │
└────────┬────────┘
         │
         │
┌────────▼────────┐         ┌─────────────────┐
│     GAMES       │         │     TEAMS       │
│ (Dimension)     │◄───────►│ (Dimension)     │
│                 │         │                 │
│ • game_id (PK)  │         │ • team_id (PK)  │
│ • uuid (UNIQUE) │         │ • uuid (UNIQUE) │
│ • nhl_game_id   │         │ • nhl_team_id   │
│ • season        │         │ • team_code     │
│ • game_status   │         │ • team_name     │
│ • home_team_id  │         │ • division      │
│ • away_team_id  │         └────────┬────────┘
│ • venue_id (FK) │                  │
└────────┬────────┘                  │
         │                           │
         │                  ┌────────▼────────┐
         │                  │    PLAYERS      │
         │                  │ (Dimension)     │
         │                  │                 │
         │                  │ • player_id (PK)│
         │                  │ • uuid (UNIQUE) │
         │                  │ • nhl_player_id │
         │                  │ • full_name     │
         │                  │ • position      │
         │                  │ • team_id (FK)  │
         │                  └────────┬────────┘
         │                           │
         │                           │
┌────────▼─────────────────────────────────────▼────────┐
│                  CRAWLER_RUNS                         │
│              (Operational Tracking)                    │
│                                                        │
│ • run_id (PK)                                         │
│ • uuid (UNIQUE)                                       │
│ • crawler_instance_id                                 │
│ • game_id (FK)                                        │
│ • status (RUNNING, SUCCESS, FAILED)                   │
│ • events_captured                                     │
└────────┬───────────────────────────────────────────────┘
         │
         │
┌────────▼────────────────────────────────────────────────┐
│                    EVENTS                               │
│                 (Fact Table)                            │
│              ⚡ TIME-SERIES PARTITIONED                 │
│                                                         │
│ • event_id (PK)                                        │
│ • uuid (UNIQUE)                                        │
│ • event_type (goal, shot, penalty, etc.)              │
│ • event_timestamp (partition key)                     │
│ • captured_at                                         │
│ • game_id (FK) ───────┐                              │
│ • crawler_run_id (FK) │                              │
│ • team_id (FK)         │                              │
│ • player_id (FK)       │                              │
│ • event_data (JSONB)   │                              │
│ • x_coord, y_coord     │                              │
│ • is_processed         │                              │
└────────┬───────────────┘                              │
         │                                               │
         │                                               │
┌────────▼────────────────────────────────────────────────┐
│             EVENT_STREAM_QUEUE                         │
│           (Data Lake Streaming)                        │
│                                                         │
│ • queue_id (PK)                                        │
│ • uuid (UNIQUE)                                        │
│ • event_id (FK)                                        │
│ • event_uuid (FK)                                      │
│ • stream_status (PENDING, STREAMING, COMPLETED)       │
│ • queued_at                                           │
│ • streamed_at                                         │
└─────────────────────────────────────────────────────────┘
```

## Table Relationships

### Core Relationships

1. **GAMES ↔ TEAMS** (Many-to-Many through home/away)
   - Each game has one home team and one away team
   - Each team can play in multiple games

2. **GAMES → VENUES** (Many-to-One)
   - Each game is played at one venue
   - Each venue hosts multiple games

3. **PLAYERS → TEAMS** (Many-to-One)
   - Each player belongs to one current team
   - Each team has multiple players

4. **EVENTS → GAMES** (Many-to-One)
   - Each event belongs to one game
   - Each game has many events

5. **EVENTS → CRAWLER_RUNS** (Many-to-One)
   - Each event is captured by one crawler run
   - Each crawler run captures many events

6. **EVENTS → TEAMS/PLAYERS** (Many-to-One, Optional)
   - Events may reference a team (for team events)
   - Events may reference one or two players

7. **EVENTS → EVENT_STREAM_QUEUE** (One-to-One)
   - Each event triggers a queue entry for streaming
   - Automatic via trigger

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│                NHL GAMECENTER PAGE                      │
└────────────────────┬────────────────────────────────────┘
                     │
                     │ Crawler Browse
                     ▼
          ┌──────────────────────┐
          │   CRAWLER_RUNS       │
          │   run_id: 1234       │
          │   status: RUNNING    │
          └──────────┬───────────┘
                     │
                     │ Extract Events
                     ▼
          ┌──────────────────────┐
          │    EVENTS TABLE      │
          │  ┌─────────────────┐ │
          │  │ Event 1         │ │◄─── Partitioned by month
          │  │ Event 2         │ │
          │  │ Event 3         │ │
          │  └─────────────────┘ │
          └──────────┬───────────┘
                     │
                     │ Trigger: Auto-queue
                     ▼
          ┌──────────────────────┐
          │ EVENT_STREAM_QUEUE   │
          │  status: PENDING     │
          └──────────┬───────────┘
                     │
                     │ Stream Worker
                     ▼
          ┌──────────────────────┐
          │    DATA LAKE         │
          │  (S3 / BigQuery)     │
          └──────────┬───────────┘
                     │
                     │ Analytics
                     ▼
          ┌──────────────────────┐
          │  ANALYTICS LAYER     │
          │  • Player Stats      │
          │  • Team Stats        │
          │  • Event Analytics   │
          └──────────────────────┘
```

## Event Types Hierarchy

```
EVENTS (Base)
│
├── SCORING
│   └── goal
│       ├── even_strength_goal
│       ├── power_play_goal
│       ├── short_handed_goal
│       └── empty_net_goal
│
├── PLAY
│   ├── shot
│   │   ├── wrist_shot
│   │   ├── slap_shot
│   │   ├── snap_shot
│   │   └── backhand
│   ├── missed_shot
│   ├── blocked_shot
│   ├── hit
│   ├── giveaway
│   ├── takeaway
│   └── faceoff
│
├── PENALTY
│   └── penalty
│       ├── minor
│       ├── major
│       ├── misconduct
│       └── penalty_shot
│
├── STOPPAGE
│   └── stoppage
│       ├── icing
│       ├── offside
│       └── hand_pass
│
└── GAME_FLOW
    ├── period_start
    ├── period_end
    └── game_end
```

## Partitioning Strategy

```
events (Parent Table)
├── events_2024_11  [2024-11-01 to 2024-12-01)
├── events_2024_12  [2024-12-01 to 2025-01-01)
├── events_2025_01  [2025-01-01 to 2025-02-01)
├── events_2025_02  [2025-02-01 to 2025-03-01)
└── events_2025_03  [2025-03-01 to 2025-04-01)
    ↓
  (auto-create new partitions monthly)
```

## Indexes Summary

### High-Performance Indexes

**events table:**
- `event_timestamp DESC` - Time-series queries
- `game_id` - Game-specific queries
- `event_type` - Filter by event type
- `player_id` - Player statistics
- `team_id` - Team statistics
- `crawler_run_id` - Crawler traceability
- `is_processed, captured_at` - Streaming queue
- `event_data` (GIN) - JSONB queries

**games table:**
- `nhl_game_id` - NHL ID lookup
- `game_date DESC` - Temporal queries
- `game_status` - Filter by status
- `(home_team_id, away_team_id)` - Team matchups

**players table:**
- `nhl_player_id` - NHL ID lookup
- `current_team_id` - Team roster
- `(last_name, first_name)` - Name search
- `position` - Position-based queries

## Materialized Views

```
┌─────────────────────────────────────┐
│      GAME_SUMMARIES                 │
│   (Aggregated Game Stats)           │
│                                     │
│ • total_events                      │
│ • total_goals                       │
│ • total_penalties                   │
│ • last_event_time                   │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│    PLAYER_EVENT_SUMMARIES           │
│   (Player Performance Metrics)      │
│                                     │
│ • event_count by type               │
│ • date-based aggregation            │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│    TEAM_EVENT_SUMMARIES             │
│   (Team Performance Metrics)        │
│                                     │
│ • event_count by type               │
│ • events_while_winning/losing       │
└─────────────────────────────────────┘
```

## Key Design Decisions

### 1. UUID External References
- Every entity has a **UUID field** for external references
- Auto-generated using `uuid_generate_v4()`
- Used for:
  - API endpoints (never expose internal IDs)
  - Data lake cross-references
  - Cross-system synchronization
  - External integrations
- Internal operations still use integer PKs for performance

### 2. Event Immutability
- Events are **never updated**, only inserted
- Historical accuracy preserved
- Simplifies replication and streaming

### 2. Time-Series Partitioning
- Monthly partitions by `event_timestamp`
- Fast queries on recent data
- Easy archival of old data
- Better vacuum performance

### 3. JSONB for Flexibility
- `event_data` stores complete NHL payload
- Schema can evolve without migrations
- Enables complex analytics queries
- GIN index for fast JSONB queries

### 4. Crawler Traceability
- Every event links to `crawler_run_id`
- Audit trail for data quality
- Performance monitoring
- Error tracking and debugging

### 5. Dual Timestamps
- `event_timestamp` - When event occurred in game
- `captured_at` - When crawler captured it
- Enables latency analysis
- Supports time travel queries

### 6. Denormalized Views
- Materialized views for common queries
- Pre-aggregated for performance
- Refresh on schedule or manually
- Trade storage for speed

## Storage Estimates

### Per Event (Average)
- Row overhead: ~40 bytes
- Fixed columns: ~120 bytes
- JSONB data: ~500-2000 bytes
- **Total per event: ~700-2200 bytes**

### Per Game
- Average events per game: ~500-800
- Storage per game: ~500 KB - 1.5 MB

### Per Season
- Games per season: ~1,300
- Total events: ~650,000 - 1,000,000
- **Season storage: ~650 MB - 2 GB**

### Multi-Season (5 years)
- Total storage: ~3-10 GB
- With indexes: ~6-20 GB
- **Very manageable for PostgreSQL**

## Query Performance Targets

- **Single game events**: < 50ms
- **Player season stats**: < 100ms
- **Team comparisons**: < 200ms
- **Date range aggregations**: < 500ms
- **Full-text search**: < 1s

## Scalability Considerations

### Horizontal Scaling
- Partition by season for multi-year data
- Archive old seasons to separate tables
- Use connection pooling (PgBouncer)

### Vertical Scaling
- PostgreSQL handles 10M+ events easily
- Add read replicas for analytics
- Separate OLTP and OLAP workloads

### Data Lake Integration
- Stream to S3/BigQuery for long-term analytics
- Keep hot data (current season) in PostgreSQL
- Cold data in data lake

## Next Steps

1. ✅ Schema designed
2. [ ] Install PostgreSQL
3. [ ] Create database and run schema.sql
4. [ ] Set up Prisma ORM
5. [ ] Implement crawler database layer
6. [ ] Test with sample data
7. [ ] Set up streaming pipeline

