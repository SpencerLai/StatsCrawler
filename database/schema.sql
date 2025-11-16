-- StatsCrawler Database Schema
-- PostgreSQL 14+
-- Event-driven architecture for NHL game data

-- ============================================================================
-- EXTENSIONS
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- For text search

-- ============================================================================
-- REFERENCE TABLES (Dimensions)
-- ============================================================================

-- Teams
CREATE TABLE teams (
	team_id SERIAL PRIMARY KEY,
	nhl_team_id INTEGER UNIQUE NOT NULL,
	team_code VARCHAR(10) UNIQUE NOT NULL,
	team_name VARCHAR(100) NOT NULL,
	team_full_name VARCHAR(100),
	city VARCHAR(100),
	abbreviation VARCHAR(5),
	division VARCHAR(50),
	conference VARCHAR(50),
	logo_url TEXT,
	primary_color VARCHAR(7),
	secondary_color VARCHAR(7),
	active BOOLEAN DEFAULT TRUE,
	created_at TIMESTAMPTZ DEFAULT NOW(),
	updated_at TIMESTAMPTZ DEFAULT NOW(),
	team_data JSONB
);

CREATE INDEX idx_teams_code ON teams(team_code);
CREATE INDEX idx_teams_nhl_id ON teams(nhl_team_id);
CREATE INDEX idx_teams_active ON teams(active) WHERE active = TRUE;

-- Venues
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

-- Players
CREATE TABLE players (
	player_id SERIAL PRIMARY KEY,
	nhl_player_id INTEGER UNIQUE NOT NULL,
	first_name VARCHAR(100),
	last_name VARCHAR(100) NOT NULL,
	full_name VARCHAR(200),
	jersey_number INTEGER,
	current_team_id INTEGER REFERENCES teams(team_id),
	position VARCHAR(10),
	shoots VARCHAR(1),
	catches VARCHAR(1),
	height_inches INTEGER,
	weight_pounds INTEGER,
	birth_date DATE,
	birth_city VARCHAR(100),
	birth_country VARCHAR(100),
	active BOOLEAN DEFAULT TRUE,
	headshot_url TEXT,
	created_at TIMESTAMPTZ DEFAULT NOW(),
	updated_at TIMESTAMPTZ DEFAULT NOW(),
	player_data JSONB
);

CREATE INDEX idx_players_nhl_id ON players(nhl_player_id);
CREATE INDEX idx_players_team ON players(current_team_id);
CREATE INDEX idx_players_name ON players(last_name, first_name);
CREATE INDEX idx_players_position ON players(position);
CREATE INDEX idx_players_active ON players(active) WHERE active = TRUE;

-- Event Types Reference
CREATE TABLE event_types (
	event_type_id SERIAL PRIMARY KEY,
	event_type VARCHAR(50) UNIQUE NOT NULL,
	event_category VARCHAR(50),
	display_name VARCHAR(100),
	description TEXT,
	is_scoring_play BOOLEAN DEFAULT FALSE,
	is_penalty BOOLEAN DEFAULT FALSE,
	affects_game_state BOOLEAN DEFAULT TRUE,
	created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- GAME TABLES
-- ============================================================================

-- Games
CREATE TABLE games (
	game_id BIGSERIAL PRIMARY KEY,
	nhl_game_id VARCHAR(50) UNIQUE NOT NULL,
	season VARCHAR(10) NOT NULL,
	game_type VARCHAR(20),
	home_team_id INTEGER NOT NULL REFERENCES teams(team_id),
	away_team_id INTEGER NOT NULL REFERENCES teams(team_id),
	game_date DATE NOT NULL,
	game_datetime TIMESTAMPTZ,
	venue_id INTEGER REFERENCES venues(venue_id),
	game_status VARCHAR(20) NOT NULL,
	current_period INTEGER,
	current_period_time VARCHAR(20),
	home_score INTEGER DEFAULT 0,
	away_score INTEGER DEFAULT 0,
	gamecenter_url TEXT,
	created_at TIMESTAMPTZ DEFAULT NOW(),
	updated_at TIMESTAMPTZ DEFAULT NOW(),
	first_crawled_at TIMESTAMPTZ,
	last_crawled_at TIMESTAMPTZ,
	game_data JSONB
);

CREATE INDEX idx_games_nhl_id ON games(nhl_game_id);
CREATE INDEX idx_games_date ON games(game_date DESC);
CREATE INDEX idx_games_status ON games(game_status);
CREATE INDEX idx_games_teams ON games(home_team_id, away_team_id);
CREATE INDEX idx_games_season ON games(season);

-- ============================================================================
-- CRAWLER TRACKING
-- ============================================================================

-- Crawler Runs
CREATE TABLE crawler_runs (
	run_id BIGSERIAL PRIMARY KEY,
	crawler_instance_id VARCHAR(100),
	crawler_version VARCHAR(20),
	started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
	completed_at TIMESTAMPTZ,
	duration_seconds INTEGER,
	game_id BIGINT REFERENCES games(game_id),
	target_url TEXT NOT NULL,
	status VARCHAR(20) NOT NULL,
	error_message TEXT,
	events_captured INTEGER DEFAULT 0,
	pages_visited INTEGER DEFAULT 0,
	browser_type VARCHAR(50),
	browser_version VARCHAR(50),
	user_agent TEXT,
	run_metadata JSONB
);

CREATE INDEX idx_crawler_game ON crawler_runs(game_id);
CREATE INDEX idx_crawler_status ON crawler_runs(status, started_at DESC);
CREATE INDEX idx_crawler_started ON crawler_runs(started_at DESC);

-- ============================================================================
-- EVENTS TABLE (Fact Table) - Partitioned by time
-- ============================================================================

CREATE TABLE events (
	event_id BIGSERIAL,
	event_type VARCHAR(50) NOT NULL,
	event_subtype VARCHAR(50),
	event_timestamp TIMESTAMPTZ NOT NULL,
	captured_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
	game_time VARCHAR(20),
	period INTEGER,
	period_type VARCHAR(20),
	game_id BIGINT NOT NULL REFERENCES games(game_id),
	crawler_run_id BIGINT NOT NULL REFERENCES crawler_runs(run_id),
	team_id INTEGER REFERENCES teams(team_id),
	player_id INTEGER REFERENCES players(player_id),
	secondary_player_id INTEGER REFERENCES players(player_id),
	event_data JSONB NOT NULL,
	x_coord DECIMAL(5,2),
	y_coord DECIMAL(5,2),
	home_score INTEGER,
	away_score INTEGER,
	source_url TEXT,
	is_processed BOOLEAN DEFAULT FALSE,
	processed_at TIMESTAMPTZ,
	PRIMARY KEY (event_id, event_timestamp)
) PARTITION BY RANGE (event_timestamp);

-- Create initial partitions (November 2024 - March 2025)
CREATE TABLE events_2024_11 PARTITION OF events
	FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');

CREATE TABLE events_2024_12 PARTITION OF events
	FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');

CREATE TABLE events_2025_01 PARTITION OF events
	FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE events_2025_02 PARTITION OF events
	FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

CREATE TABLE events_2025_03 PARTITION OF events
	FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');

-- Indexes on events (applied to all partitions)
CREATE INDEX idx_events_game_id ON events(game_id);
CREATE INDEX idx_events_timestamp ON events(event_timestamp DESC);
CREATE INDEX idx_events_type ON events(event_type);
CREATE INDEX idx_events_player ON events(player_id) WHERE player_id IS NOT NULL;
CREATE INDEX idx_events_team ON events(team_id) WHERE team_id IS NOT NULL;
CREATE INDEX idx_events_crawler ON events(crawler_run_id);
CREATE INDEX idx_events_processing ON events(is_processed, captured_at) WHERE NOT is_processed;
CREATE INDEX idx_events_jsonb ON events USING GIN (event_data);

-- ============================================================================
-- STREAMING SUPPORT
-- ============================================================================

-- Event Stream Queue for Data Lake
CREATE TABLE event_stream_queue (
	queue_id BIGSERIAL PRIMARY KEY,
	event_id BIGINT NOT NULL,
	event_timestamp TIMESTAMPTZ NOT NULL,
	queued_at TIMESTAMPTZ DEFAULT NOW(),
	streamed_at TIMESTAMPTZ,
	stream_status VARCHAR(20) DEFAULT 'PENDING',
	retry_count INTEGER DEFAULT 0,
	error_message TEXT
);

CREATE INDEX idx_stream_queue_status ON event_stream_queue(stream_status, queued_at);
CREATE INDEX idx_stream_queue_event ON event_stream_queue(event_id, event_timestamp);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
	NEW.updated_at = NOW();
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_teams_updated_at
	BEFORE UPDATE ON teams
	FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trigger_players_updated_at
	BEFORE UPDATE ON players
	FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trigger_games_updated_at
	BEFORE UPDATE ON games
	FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Queue events for streaming
CREATE OR REPLACE FUNCTION queue_event_for_streaming()
RETURNS TRIGGER AS $$
BEGIN
	INSERT INTO event_stream_queue (event_id, event_timestamp)
	VALUES (NEW.event_id, NEW.event_timestamp);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_queue_event
	AFTER INSERT ON events
	FOR EACH ROW
	EXECUTE FUNCTION queue_event_for_streaming();

-- Update crawler run statistics
CREATE OR REPLACE FUNCTION update_crawler_stats()
RETURNS TRIGGER AS $$
BEGIN
	UPDATE crawler_runs
	SET events_captured = events_captured + 1
	WHERE run_id = NEW.crawler_run_id;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_crawler_stats
	AFTER INSERT ON events
	FOR EACH ROW
	EXECUTE FUNCTION update_crawler_stats();

-- ============================================================================
-- MATERIALIZED VIEWS
-- ============================================================================

-- Game Summaries
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

-- ============================================================================
-- VIEWS
-- ============================================================================

-- Events for Export (Data Lake)
CREATE VIEW events_for_export AS
SELECT
	e.event_id,
	e.event_type,
	e.event_subtype,
	e.event_timestamp,
	e.captured_at,
	e.game_time,
	e.period,
	g.nhl_game_id,
	g.season,
	g.game_date,
	t.team_code,
	t.team_name,
	p.nhl_player_id,
	p.full_name AS player_name,
	p.position,
	p2.nhl_player_id AS secondary_player_nhl_id,
	p2.full_name AS secondary_player_name,
	cr.crawler_instance_id,
	cr.crawler_version,
	cr.started_at AS crawler_run_started,
	e.event_data,
	e.x_coord,
	e.y_coord,
	e.home_score,
	e.away_score,
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

-- ============================================================================
-- SEED DATA
-- ============================================================================

-- Event Types
INSERT INTO event_types (event_type, event_category, display_name, is_scoring_play, is_penalty) VALUES
	('goal', 'SCORING', 'Goal', TRUE, FALSE),
	('shot', 'PLAY', 'Shot', FALSE, FALSE),
	('missed_shot', 'PLAY', 'Missed Shot', FALSE, FALSE),
	('blocked_shot', 'PLAY', 'Blocked Shot', FALSE, FALSE),
	('hit', 'PLAY', 'Hit', FALSE, FALSE),
	('giveaway', 'PLAY', 'Giveaway', FALSE, FALSE),
	('takeaway', 'PLAY', 'Takeaway', FALSE, FALSE),
	('faceoff', 'PLAY', 'Faceoff', FALSE, FALSE),
	('penalty', 'PENALTY', 'Penalty', FALSE, TRUE),
	('stoppage', 'STOPPAGE', 'Stoppage', FALSE, FALSE),
	('period_start', 'GAME_FLOW', 'Period Start', FALSE, FALSE),
	('period_end', 'GAME_FLOW', 'Period End', FALSE, FALSE),
	('game_end', 'GAME_FLOW', 'Game End', FALSE, FALSE);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Refresh materialized views
CREATE OR REPLACE FUNCTION refresh_analytics_views()
RETURNS void AS $$
BEGIN
	REFRESH MATERIALIZED VIEW CONCURRENTLY game_summaries;
END;
$$ LANGUAGE plpgsql;

-- Archive old events
CREATE OR REPLACE FUNCTION archive_old_events(months_old INTEGER)
RETURNS INTEGER AS $$
DECLARE
	archived_count INTEGER;
BEGIN
	-- This function would move old events to archive storage
	-- Implementation depends on archival strategy
	RETURN 0;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE events IS 'Core fact table storing all game events captured by crawlers';
COMMENT ON TABLE games IS 'Dimension table for NHL games';
COMMENT ON TABLE crawler_runs IS 'Tracks individual crawler execution runs';
COMMENT ON TABLE event_stream_queue IS 'Queue for streaming events to data lake';
COMMENT ON COLUMN events.event_data IS 'Complete event payload in JSONB format for flexibility';
COMMENT ON COLUMN events.is_processed IS 'Flag indicating if event has been streamed to data lake';

