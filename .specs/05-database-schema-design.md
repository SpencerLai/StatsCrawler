# Chat Prompt 05: Database Schema Design

## Date
November 16, 2025

## User Request
> Lets have a deep dive into database schema design. The database should log every event from the page and store them as indiviual rows with time and reference of the crawler id. The data will then be stream to a datalake for advance analytics broken down by player, team or the type of events.

## Architecture Overview

### Event-Driven Design
StatsCrawler will use an **event-driven architecture** where every action, change, or data point from NHL gamecenter pages is logged as an individual event.

### Data Flow
```
NHL Gamecenter Page
        ↓
    Crawler (with crawler_id)
        ↓
   Capture Events (timestamp + crawler_id)
        ↓
  PostgreSQL Events Table (transactional storage)
        ↓
   Stream to Data Lake (S3, BigQuery, Snowflake, etc.)
        ↓
  Analytics Layer (player/team/event breakdowns)
```

### Key Design Principles

1. **UUID External References**: Every entity has a UUID for external identification
2. **Immutable Events**: Each event is never modified, only inserted
3. **Time-Series Data**: Every event has a precise timestamp
4. **Crawler Traceability**: Each event references the crawler that captured it
5. **Normalization**: Reference data (teams, players, games) stored separately
6. **Streaming Ready**: Schema optimized for streaming to data lakes
7. **Analytics Friendly**: Denormalized views for quick analytics

## Core Schema Design

### 1. Events Table (Fact Table)
The central table that logs every event captured from NHL pages.

```sql
CREATE TABLE events (
	event_id BIGSERIAL PRIMARY KEY,
	uuid UUID NOT NULL DEFAULT uuid_generate_v4(),  -- Unique external reference
	
	-- Event Classification
	event_type VARCHAR(50) NOT NULL,  -- 'goal', 'penalty', 'shot', 'faceoff', 'hit', etc.
	event_subtype VARCHAR(50),        -- Specific details like 'power_play_goal', 'wrist_shot'

	-- Temporal Data
	event_timestamp TIMESTAMPTZ NOT NULL,     -- When event occurred in game
	captured_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),  -- When crawler captured it
	game_time VARCHAR(20),                    -- Game clock time (e.g., "12:34" in period)
	period INTEGER,                           -- Period number (1, 2, 3, OT, SO)
	period_type VARCHAR(20),                  -- 'REGULAR', 'OVERTIME', 'SHOOTOUT'

	-- References
	game_id BIGINT NOT NULL REFERENCES games(game_id),
	crawler_run_id BIGINT NOT NULL REFERENCES crawler_runs(run_id),
	team_id INTEGER REFERENCES teams(team_id),           -- Team involved (if applicable)
	player_id INTEGER REFERENCES players(player_id),     -- Primary player
	secondary_player_id INTEGER REFERENCES players(player_id),  -- Secondary player (assists, penalties drawn)

	-- Event Details (JSONB for flexibility)
	event_data JSONB NOT NULL,  -- Complete event payload from NHL

	-- Coordinates (for spatial analysis)
	x_coord DECIMAL(5,2),  -- X coordinate on ice
	y_coord DECIMAL(5,2),  -- Y coordinate on ice

	-- Scores at time of event
	home_score INTEGER,
	away_score INTEGER,

	-- Metadata
	source_url TEXT,            -- URL where event was captured
	is_processed BOOLEAN DEFAULT FALSE,  -- For streaming pipeline
	processed_at TIMESTAMPTZ,

	-- Indexing for time-series queries
	CONSTRAINT events_time_idx CHECK (event_timestamp IS NOT NULL)
);

-- Indexes for performance
CREATE INDEX idx_events_game_id ON events(game_id);
CREATE INDEX idx_events_timestamp ON events(event_timestamp DESC);
CREATE INDEX idx_events_type ON events(event_type);
CREATE INDEX idx_events_player ON events(player_id) WHERE player_id IS NOT NULL;
CREATE INDEX idx_events_team ON events(team_id) WHERE team_id IS NOT NULL;
CREATE INDEX idx_events_crawler ON events(crawler_run_id);
CREATE INDEX idx_events_processing ON events(is_processed, captured_at) WHERE NOT is_processed;
CREATE INDEX idx_events_jsonb ON events USING GIN (event_data);

-- Partitioning by month for scalability
CREATE TABLE events_2024_11 PARTITION OF events
	FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');
```

### 2. Games Table (Dimension)
Stores game-level information.

```sql
CREATE TABLE games (
	game_id BIGSERIAL PRIMARY KEY,

	-- NHL Identifiers
	nhl_game_id VARCHAR(50) UNIQUE NOT NULL,  -- Official NHL game ID
	season VARCHAR(10) NOT NULL,               -- e.g., '2024-25'
	game_type VARCHAR(20),                     -- 'REGULAR', 'PLAYOFF', 'PRESEASON'

	-- Teams
	home_team_id INTEGER NOT NULL REFERENCES teams(team_id),
	away_team_id INTEGER NOT NULL REFERENCES teams(team_id),

	-- Timing
	game_date DATE NOT NULL,
	game_datetime TIMESTAMPTZ,
	venue_id INTEGER REFERENCES venues(venue_id),

	-- Status
	game_status VARCHAR(20) NOT NULL,  -- 'SCHEDULED', 'LIVE', 'FINAL', 'POSTPONED'
	current_period INTEGER,
	current_period_time VARCHAR(20),

	-- Scores
	home_score INTEGER DEFAULT 0,
	away_score INTEGER DEFAULT 0,

	-- URLs
	gamecenter_url TEXT,

	-- Metadata
	created_at TIMESTAMPTZ DEFAULT NOW(),
	updated_at TIMESTAMPTZ DEFAULT NOW(),
	first_crawled_at TIMESTAMPTZ,
	last_crawled_at TIMESTAMPTZ,

	-- Additional game data
	game_data JSONB
);

CREATE INDEX idx_games_nhl_id ON games(nhl_game_id);
CREATE INDEX idx_games_date ON games(game_date DESC);
CREATE INDEX idx_games_status ON games(game_status);
CREATE INDEX idx_games_teams ON games(home_team_id, away_team_id);
```

### 3. Crawler Runs Table
Tracks each crawler execution for traceability.

```sql
CREATE TABLE crawler_runs (
	run_id BIGSERIAL PRIMARY KEY,

	-- Crawler Identification
	crawler_instance_id VARCHAR(100),  -- Unique ID for crawler instance
	crawler_version VARCHAR(20),        -- Software version

	-- Timing
	started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
	completed_at TIMESTAMPTZ,
	duration_seconds INTEGER,

	-- Target
	game_id BIGINT REFERENCES games(game_id),
	target_url TEXT NOT NULL,

	-- Status
	status VARCHAR(20) NOT NULL,  -- 'RUNNING', 'SUCCESS', 'FAILED', 'PARTIAL'
	error_message TEXT,

	-- Statistics
	events_captured INTEGER DEFAULT 0,
	pages_visited INTEGER DEFAULT 0,

	-- Browser Info
	browser_type VARCHAR(50),     -- 'chrome', 'chromium'
	browser_version VARCHAR(50),
	user_agent TEXT,

	-- Metadata
	run_metadata JSONB
);

CREATE INDEX idx_crawler_game ON crawler_runs(game_id);
CREATE INDEX idx_crawler_status ON crawler_runs(status, started_at DESC);
CREATE INDEX idx_crawler_started ON crawler_runs(started_at DESC);
```

### 4. Teams Table (Dimension)
NHL teams reference data.

```sql
CREATE TABLE teams (
	team_id SERIAL PRIMARY KEY,

	-- NHL Identifiers
	nhl_team_id INTEGER UNIQUE NOT NULL,
	team_code VARCHAR(10) UNIQUE NOT NULL,  -- 'TOR', 'MTL', 'BOS', etc.

	-- Team Info
	team_name VARCHAR(100) NOT NULL,
	team_full_name VARCHAR(100),
	city VARCHAR(100),
	abbreviation VARCHAR(5),

	-- Division/Conference
	division VARCHAR(50),
	conference VARCHAR(50),

	-- Metadata
	logo_url TEXT,
	primary_color VARCHAR(7),   -- Hex color
	secondary_color VARCHAR(7),

	active BOOLEAN DEFAULT TRUE,
	created_at TIMESTAMPTZ DEFAULT NOW(),
	updated_at TIMESTAMPTZ DEFAULT NOW(),

	team_data JSONB
);

CREATE INDEX idx_teams_code ON teams(team_code);
CREATE INDEX idx_teams_nhl_id ON teams(nhl_team_id);
```

### 5. Players Table (Dimension)
NHL players reference data.

```sql
CREATE TABLE players (
	player_id SERIAL PRIMARY KEY,

	-- NHL Identifiers
	nhl_player_id INTEGER UNIQUE NOT NULL,

	-- Personal Info
	first_name VARCHAR(100),
	last_name VARCHAR(100) NOT NULL,
	full_name VARCHAR(200),
	jersey_number INTEGER,

	-- Current Team
	current_team_id INTEGER REFERENCES teams(team_id),

	-- Player Details
	position VARCHAR(10),  -- 'C', 'LW', 'RW', 'D', 'G'
	shoots VARCHAR(1),     -- 'L', 'R'
	catches VARCHAR(1),    -- 'L', 'R' (for goalies)

	-- Physical
	height_inches INTEGER,
	weight_pounds INTEGER,
	birth_date DATE,
	birth_city VARCHAR(100),
	birth_country VARCHAR(100),

	-- Status
	active BOOLEAN DEFAULT TRUE,

	-- Metadata
	headshot_url TEXT,
	created_at TIMESTAMPTZ DEFAULT NOW(),
	updated_at TIMESTAMPTZ DEFAULT NOW(),

	player_data JSONB
);

CREATE INDEX idx_players_nhl_id ON players(nhl_player_id);
CREATE INDEX idx_players_team ON players(current_team_id);
CREATE INDEX idx_players_name ON players(last_name, first_name);
CREATE INDEX idx_players_position ON players(position);
```

### 6. Venues Table (Dimension)
Arena/venue information.

```sql
CREATE TABLE venues (
	venue_id SERIAL PRIMARY KEY,

	nhl_venue_id INTEGER UNIQUE,
	venue_name VARCHAR(200) NOT NULL,
	city VARCHAR(100),
	state_province VARCHAR(100),
	country VARCHAR(100),

	timezone VARCHAR(50),
	capacity INTEGER,

	created_at TIMESTAMPTZ DEFAULT NOW(),
	venue_data JSONB
);
```

### 7. Event Types Reference Table
Standardized event types for analytics.

```sql
CREATE TABLE event_types (
	event_type_id SERIAL PRIMARY KEY,

	event_type VARCHAR(50) UNIQUE NOT NULL,
	event_category VARCHAR(50),  -- 'SCORING', 'PENALTY', 'PLAY', 'STOPPAGE'
	display_name VARCHAR(100),
	description TEXT,

	-- Analytics flags
	is_scoring_play BOOLEAN DEFAULT FALSE,
	is_penalty BOOLEAN DEFAULT FALSE,
	affects_game_state BOOLEAN DEFAULT TRUE,

	created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Pre-populate with known event types
INSERT INTO event_types (event_type, event_category, display_name, is_scoring_play) VALUES
	('goal', 'SCORING', 'Goal', TRUE),
	('shot', 'PLAY', 'Shot', FALSE),
	('missed_shot', 'PLAY', 'Missed Shot', FALSE),
	('blocked_shot', 'PLAY', 'Blocked Shot', FALSE),
	('hit', 'PLAY', 'Hit', FALSE),
	('faceoff', 'PLAY', 'Faceoff', FALSE),
	('penalty', 'PENALTY', 'Penalty', FALSE),
	('stoppage', 'STOPPAGE', 'Stoppage', FALSE),
	('period_start', 'GAME_FLOW', 'Period Start', FALSE),
	('period_end', 'GAME_FLOW', 'Period End', FALSE);
```

## Materialized Views for Analytics

### 1. Game Summary View

```sql
CREATE MATERIALIZED VIEW game_summaries AS
SELECT
	g.game_id,
	g.nhl_game_id,
	g.game_date,
	g.game_status,
	ht.team_name AS home_team,
	at.team_name AS away_team,
	g.home_score,
	g.away_score,
	COUNT(e.event_id) AS total_events,
	COUNT(CASE WHEN e.event_type = 'goal' THEN 1 END) AS total_goals,
	COUNT(CASE WHEN e.event_type = 'penalty' THEN 1 END) AS total_penalties,
	COUNT(CASE WHEN e.event_type = 'shot' THEN 1 END) AS total_shots,
	MAX(e.captured_at) AS last_event_time
FROM games g
LEFT JOIN teams ht ON g.home_team_id = ht.team_id
LEFT JOIN teams at ON g.away_team_id = at.team_id
LEFT JOIN events e ON g.game_id = e.game_id
GROUP BY g.game_id, g.nhl_game_id, g.game_date, g.game_status,
         ht.team_name, at.team_name, g.home_score, g.away_score;

CREATE UNIQUE INDEX idx_game_summaries_game_id ON game_summaries(game_id);
```

### 2. Player Event Summary

```sql
CREATE MATERIALIZED VIEW player_event_summaries AS
SELECT
	p.player_id,
	p.full_name,
	p.position,
	t.team_name,
	e.event_type,
	DATE(e.event_timestamp) AS event_date,
	COUNT(*) AS event_count,
	MIN(e.event_timestamp) AS first_event,
	MAX(e.event_timestamp) AS last_event
FROM events e
JOIN players p ON e.player_id = p.player_id
LEFT JOIN teams t ON p.current_team_id = t.team_id
GROUP BY p.player_id, p.full_name, p.position, t.team_name,
         e.event_type, DATE(e.event_timestamp);

CREATE INDEX idx_player_summaries_player ON player_event_summaries(player_id, event_date);
CREATE INDEX idx_player_summaries_type ON player_event_summaries(event_type);
```

### 3. Team Event Summary

```sql
CREATE MATERIALIZED VIEW team_event_summaries AS
SELECT
	t.team_id,
	t.team_name,
	e.event_type,
	DATE(e.event_timestamp) AS event_date,
	COUNT(*) AS event_count,
	COUNT(CASE WHEN e.home_score > e.away_score THEN 1 END) AS events_while_winning,
	COUNT(CASE WHEN e.home_score < e.away_score THEN 1 END) AS events_while_losing,
	AVG(EXTRACT(EPOCH FROM (e.captured_at - e.event_timestamp))) AS avg_capture_delay_seconds
FROM events e
JOIN teams t ON e.team_id = t.team_id
GROUP BY t.team_id, t.team_name, e.event_type, DATE(e.event_timestamp);

CREATE INDEX idx_team_summaries_team ON team_event_summaries(team_id, event_date);
CREATE INDEX idx_team_summaries_type ON team_event_summaries(event_type);
```

## Streaming to Data Lake

### Streaming Strategy

#### 1. Change Data Capture (CDC)
Use PostgreSQL logical replication or trigger-based CDC to stream events.

```sql
-- Create a streaming queue table
CREATE TABLE event_stream_queue (
	queue_id BIGSERIAL PRIMARY KEY,
	event_id BIGINT NOT NULL REFERENCES events(event_id),
	queued_at TIMESTAMPTZ DEFAULT NOW(),
	streamed_at TIMESTAMPTZ,
	stream_status VARCHAR(20) DEFAULT 'PENDING',  -- 'PENDING', 'STREAMING', 'COMPLETED', 'FAILED'
	retry_count INTEGER DEFAULT 0,
	error_message TEXT
);

CREATE INDEX idx_stream_queue_status ON event_stream_queue(stream_status, queued_at);

-- Trigger to auto-queue new events
CREATE OR REPLACE FUNCTION queue_event_for_streaming()
RETURNS TRIGGER AS $$
BEGIN
	INSERT INTO event_stream_queue (event_id)
	VALUES (NEW.event_id);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_queue_event
	AFTER INSERT ON events
	FOR EACH ROW
	EXECUTE FUNCTION queue_event_for_streaming();
```

#### 2. Batch Export View
For periodic batch exports to data lake.

```sql
CREATE VIEW events_for_export AS
SELECT
	e.event_id,
	e.event_type,
	e.event_subtype,
	e.event_timestamp,
	e.captured_at,
	e.game_time,
	e.period,

	-- Game info
	g.nhl_game_id,
	g.season,
	g.game_date,

	-- Team info
	t.team_code,
	t.team_name,

	-- Player info
	p.nhl_player_id,
	p.full_name AS player_name,
	p.position,

	-- Secondary player
	p2.nhl_player_id AS secondary_player_nhl_id,
	p2.full_name AS secondary_player_name,

	-- Crawler info
	cr.crawler_instance_id,
	cr.crawler_version,
	cr.started_at AS crawler_run_started,

	-- Event details
	e.event_data,
	e.x_coord,
	e.y_coord,
	e.home_score,
	e.away_score,

	-- Processing status
	e.is_processed,
	e.processed_at

FROM events e
JOIN games g ON e.game_id = g.game_id
JOIN crawler_runs cr ON e.crawler_run_id = cr.run_id
LEFT JOIN teams t ON e.team_id = t.team_id
LEFT JOIN players p ON e.player_id = p.player_id
LEFT JOIN players p2 ON e.secondary_player_id = p2.player_id
WHERE e.is_processed = FALSE
ORDER BY e.captured_at;
```

### Data Lake Schema

#### Parquet/Avro Schema for S3/BigQuery

```json
{
  "type": "record",
  "name": "NHLEvent",
  "namespace": "com.statscrawler.events",
  "fields": [
    {"name": "event_id", "type": "long"},
    {"name": "event_type", "type": "string"},
    {"name": "event_subtype", "type": ["null", "string"]},
    {"name": "event_timestamp", "type": {"type": "long", "logicalType": "timestamp-millis"}},
    {"name": "captured_at", "type": {"type": "long", "logicalType": "timestamp-millis"}},
    {"name": "game_time", "type": ["null", "string"]},
    {"name": "period", "type": ["null", "int"]},
    {"name": "nhl_game_id", "type": "string"},
    {"name": "season", "type": "string"},
    {"name": "team_code", "type": ["null", "string"]},
    {"name": "team_name", "type": ["null", "string"]},
    {"name": "player_nhl_id", "type": ["null", "int"]},
    {"name": "player_name", "type": ["null", "string"]},
    {"name": "player_position", "type": ["null", "string"]},
    {"name": "crawler_instance_id", "type": "string"},
    {"name": "crawler_version", "type": "string"},
    {"name": "event_data", "type": "string"},
    {"name": "x_coord", "type": ["null", "double"]},
    {"name": "y_coord", "type": ["null", "double"]},
    {"name": "home_score", "type": ["null", "int"]},
    {"name": "away_score", "type": ["null", "int"]}
  ]
}
```

## Performance Optimization

### 1. Partitioning Strategy

```sql
-- Partition events by month
CREATE TABLE events (
	-- ... columns ...
) PARTITION BY RANGE (event_timestamp);

-- Create partitions for each month
CREATE TABLE events_2024_11 PARTITION OF events
	FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');

CREATE TABLE events_2024_12 PARTITION OF events
	FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');

-- Auto-create future partitions
CREATE EXTENSION IF NOT EXISTS pg_partman;
```

### 2. Indexing Strategy

**Time-series indexes** for fast temporal queries:
- B-tree indexes on timestamp columns
- Partial indexes on frequently filtered columns
- GIN indexes on JSONB columns for flexible queries

### 3. Vacuum and Maintenance

```sql
-- Auto-vacuum settings for high-write tables
ALTER TABLE events SET (
	autovacuum_vacuum_scale_factor = 0.05,
	autovacuum_analyze_scale_factor = 0.02
);
```

## Data Retention Policy

```sql
-- Archive old events to cold storage
CREATE TABLE events_archive (
	LIKE events INCLUDING ALL
);

-- Function to archive old data
CREATE OR REPLACE FUNCTION archive_old_events(months_old INTEGER)
RETURNS INTEGER AS $$
DECLARE
	archived_count INTEGER;
BEGIN
	WITH moved_events AS (
		DELETE FROM events
		WHERE event_timestamp < NOW() - (months_old || ' months')::INTERVAL
		RETURNING *
	)
	INSERT INTO events_archive
	SELECT * FROM moved_events;

	GET DIAGNOSTICS archived_count = ROW_COUNT;
	RETURN archived_count;
END;
$$ LANGUAGE plpgsql;
```

## Next Steps

1. **Install PostgreSQL** and required extensions
2. **Run migration scripts** to create schema
3. **Set up Prisma ORM** with TypeScript types
4. **Implement CDC pipeline** for data lake streaming
5. **Configure partitioning** for scalability
6. **Set up monitoring** for database performance
7. **Create ETL jobs** for materialized view refresh

## Analytics Use Cases Enabled

### By Player
- Player performance over time
- Shot charts and heat maps
- Individual player events chronology
- Comparison across players

### By Team
- Team performance metrics
- Event patterns during wins/losses
- Home vs. away statistics
- Period-by-period breakdowns

### By Event Type
- Distribution of event types across games
- Correlation between event types and outcomes
- Temporal patterns (when goals/penalties occur)
- Location-based analysis (x,y coordinates)

## Technology Recommendations

### ORM: Prisma
- Excellent TypeScript support
- Auto-generated types
- Migration management
- Good performance

### Streaming: Debezium + Kafka
- Real-time CDC from PostgreSQL
- Reliable event streaming
- Integration with data lakes

### Data Lake: AWS S3 + Athena or Google BigQuery
- Cost-effective storage
- SQL query capability
- Integration with analytics tools

