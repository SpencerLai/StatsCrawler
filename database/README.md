# StatsCrawler Database

Event-driven PostgreSQL schema for NHL game data capture and streaming.

## Architecture

### Event-Driven Design
Every action from NHL gamecenter pages is logged as an immutable event with:
- Precise timestamp
- Crawler run reference
- Complete event payload (JSONB)
- Player/team/game references

### Data Flow
```
Crawler → Events Table → Stream Queue → Data Lake → Analytics
```

## Schema Overview

### Core Tables

#### 1. **events** (Fact Table)
- Primary data store for all captured events
- Partitioned by `event_timestamp` (monthly)
- Each row represents one event from NHL gamecenter
- Never modified after insert (immutable)

#### 2. **games** (Dimension)
- Game-level information
- Status tracking (scheduled, live, final)
- Links to teams and venues

#### 3. **crawler_runs** (Tracking)
- Each crawler execution logged
- Tracks success/failure
- Links to events captured

#### 4. **players** (Dimension)
- NHL player reference data
- Current team association
- Position and physical stats

#### 5. **teams** (Dimension)
- NHL team reference data
- Division/conference info
- Team colors and branding

#### 6. **event_stream_queue** (Streaming)
- Queue for data lake streaming
- Tracks processing status
- Retry logic support

## Setup Instructions

### 1. Install PostgreSQL

**macOS:**
```bash
brew install postgresql@14
brew services start postgresql@14
```

**Linux:**
```bash
sudo apt-get install postgresql-14
sudo systemctl start postgresql
```

### 2. Create Database

```bash
createdb statscrawler
```

### 3. Run Schema Creation

```bash
psql -d statscrawler -f database/schema.sql
```

### 4. Verify Installation

```bash
psql -d statscrawler -c "\dt"  # List tables
psql -d statscrawler -c "SELECT * FROM event_types;"  # Check seed data
```

## Database Configuration

### Connection String
```
postgresql://localhost:5432/statscrawler
```

### Environment Variables
Create `.env.local`:
```bash
DATABASE_URL="postgresql://localhost:5432/statscrawler"
```

## Key Features

### 1. Time-Series Partitioning
Events table is partitioned by month for:
- Fast queries on recent data
- Easy archival of old data
- Better vacuum performance

### 2. JSONB Flexibility
Event data stored as JSONB allows:
- Schema evolution without migrations
- Complex queries with GIN indexes
- Full NHL payload preservation

### 3. Automatic Streaming Queue
Trigger automatically queues events for data lake streaming:
```sql
INSERT INTO events → Trigger → event_stream_queue
```

### 4. Crawler Traceability
Every event traces back to:
- Specific crawler run
- Browser version used
- Capture timestamp vs. event timestamp

## Analytics Queries

### Events by Game
```sql
SELECT
	event_type,
	COUNT(*) as count,
	MIN(event_timestamp) as first_event,
	MAX(event_timestamp) as last_event
FROM events
WHERE game_id = 1
GROUP BY event_type
ORDER BY count DESC;
```

### Player Event Summary
```sql
SELECT
	p.full_name,
	e.event_type,
	COUNT(*) as total
FROM events e
JOIN players p ON e.player_id = p.player_id
WHERE e.game_id = 1
GROUP BY p.full_name, e.event_type
ORDER BY total DESC;
```

### Crawler Performance
```sql
SELECT
	crawler_instance_id,
	COUNT(*) as runs,
	AVG(duration_seconds) as avg_duration,
	SUM(events_captured) as total_events,
	COUNT(CASE WHEN status = 'SUCCESS' THEN 1 END) as successful_runs
FROM crawler_runs
GROUP BY crawler_instance_id;
```

### Events Ready for Streaming
```sql
SELECT COUNT(*)
FROM event_stream_queue
WHERE stream_status = 'PENDING';
```

## Maintenance

### Refresh Materialized Views
```sql
SELECT refresh_analytics_views();
```

Or manually:
```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY game_summaries;
```

### Create New Partition (monthly)
```sql
-- For April 2025
CREATE TABLE events_2025_04 PARTITION OF events
	FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');
```

### Check Partition Sizes
```sql
SELECT
	schemaname,
	tablename,
	pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE tablename LIKE 'events_%'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

## Performance Tuning

### Recommended PostgreSQL Settings
```
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 128MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 16MB
```

### Vacuum Strategy
```sql
ALTER TABLE events SET (
	autovacuum_vacuum_scale_factor = 0.05,
	autovacuum_analyze_scale_factor = 0.02
);
```

## Data Lake Streaming

### Export Format
Events are exported with denormalized data for analytics:
- Game information (season, teams, date)
- Player information (names, positions)
- Team information (codes, names)
- Crawler metadata (version, timing)
- Complete event payload

### Processing Flow
1. Event inserted → Trigger adds to queue
2. Stream worker reads from queue
3. Transform to Parquet/Avro format
4. Upload to S3/BigQuery/Snowflake
5. Mark as processed

### Query Unprocessed Events
```sql
SELECT * FROM events_for_export
LIMIT 1000;
```

## Backup Strategy

### Daily Backups
```bash
pg_dump statscrawler > backup_$(date +%Y%m%d).sql
```

### Point-in-Time Recovery
Enable WAL archiving in postgresql.conf:
```
wal_level = replica
archive_mode = on
archive_command = 'cp %p /path/to/archive/%f'
```

## Monitoring

### Active Connections
```sql
SELECT count(*) FROM pg_stat_activity
WHERE datname = 'statscrawler';
```

### Table Sizes
```sql
SELECT
	schemaname,
	tablename,
	pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Index Usage
```sql
SELECT
	schemaname,
	tablename,
	indexname,
	idx_scan as index_scans
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC;
```

## Next Steps

1. ✅ Schema created
2. [ ] Install Prisma ORM
3. [ ] Generate TypeScript types
4. [ ] Implement crawler database layer
5. [ ] Set up streaming pipeline
6. [ ] Configure backups
7. [ ] Set up monitoring

## Resources

- Schema Design: `.specs/05-database-schema-design.md`
- SQL File: `database/schema.sql`
- Prisma Setup: (coming next)

