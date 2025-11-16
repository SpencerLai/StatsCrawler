-- StatsCrawler Example Queries
-- Common analytics and operational queries

-- ============================================================================
-- GAME ANALYTICS
-- ============================================================================

-- 1. Get all events for a specific game
SELECT
	e.event_id,
	e.event_type,
	e.event_timestamp,
	e.game_time,
	e.period,
	p.full_name AS player_name,
	t.team_name,
	e.home_score,
	e.away_score,
	e.event_data
FROM events e
LEFT JOIN players p ON e.player_id = p.player_id
LEFT JOIN teams t ON e.team_id = t.team_id
WHERE e.game_id = 1
ORDER BY e.event_timestamp;

-- 2. Game event summary by type
SELECT
	event_type,
	COUNT(*) AS count,
	MIN(event_timestamp) AS first_event,
	MAX(event_timestamp) AS last_event,
	AVG(EXTRACT(EPOCH FROM (captured_at - event_timestamp))) AS avg_delay_seconds
FROM events
WHERE game_id = 1
GROUP BY event_type
ORDER BY count DESC;

-- 3. Goals with scorers and time
SELECT
	e.event_timestamp,
	e.game_time,
	e.period,
	p.full_name AS scorer,
	t.team_name AS team,
	e.home_score,
	e.away_score,
	e.event_data->>'shotType' AS shot_type
FROM events e
JOIN players p ON e.player_id = p.player_id
JOIN teams t ON e.team_id = t.team_id
WHERE e.game_id = 1 AND e.event_type = 'goal'
ORDER BY e.event_timestamp;

-- 4. Shot map data (x, y coordinates)
SELECT
	event_id,
	event_type,
	event_subtype,
	x_coord,
	y_coord,
	p.full_name AS player_name,
	CASE WHEN event_type = 'goal' THEN true ELSE false END AS is_goal
FROM events e
LEFT JOIN players p ON e.player_id = p.player_id
WHERE game_id = 1
	AND event_type IN ('shot', 'goal', 'missed_shot')
	AND x_coord IS NOT NULL
	AND y_coord IS NOT NULL;

-- ============================================================================
-- PLAYER ANALYTICS
-- ============================================================================

-- 5. Player performance in a game
SELECT
	p.full_name,
	p.position,
	COUNT(*) AS total_events,
	COUNT(CASE WHEN e.event_type = 'goal' THEN 1 END) AS goals,
	COUNT(CASE WHEN e.event_type = 'shot' THEN 1 END) AS shots,
	COUNT(CASE WHEN e.event_type = 'hit' THEN 1 END) AS hits,
	COUNT(CASE WHEN e.event_type = 'penalty' THEN 1 END) AS penalties
FROM events e
JOIN players p ON e.player_id = p.player_id
WHERE e.game_id = 1
GROUP BY p.player_id, p.full_name, p.position
ORDER BY goals DESC, shots DESC;

-- 6. Player events across all games
SELECT
	p.full_name,
	p.position,
	t.team_name,
	COUNT(DISTINCT e.game_id) AS games_played,
	COUNT(*) AS total_events,
	COUNT(CASE WHEN e.event_type = 'goal' THEN 1 END) AS total_goals,
	COUNT(CASE WHEN e.event_type = 'shot' THEN 1 END) AS total_shots
FROM events e
JOIN players p ON e.player_id = p.player_id
LEFT JOIN teams t ON p.current_team_id = t.team_id
GROUP BY p.player_id, p.full_name, p.position, t.team_name
HAVING COUNT(CASE WHEN e.event_type = 'goal' THEN 1 END) > 0
ORDER BY total_goals DESC
LIMIT 20;

-- 7. Player shooting percentage
SELECT
	p.full_name,
	COUNT(CASE WHEN e.event_type = 'goal' THEN 1 END) AS goals,
	COUNT(CASE WHEN e.event_type IN ('shot', 'goal') THEN 1 END) AS shots,
	ROUND(
		100.0 * COUNT(CASE WHEN e.event_type = 'goal' THEN 1 END) /
		NULLIF(COUNT(CASE WHEN e.event_type IN ('shot', 'goal') THEN 1 END), 0),
		2
	) AS shooting_pct
FROM events e
JOIN players p ON e.player_id = p.player_id
GROUP BY p.player_id, p.full_name
HAVING COUNT(CASE WHEN e.event_type IN ('shot', 'goal') THEN 1 END) >= 10
ORDER BY shooting_pct DESC
LIMIT 20;

-- ============================================================================
-- TEAM ANALYTICS
-- ============================================================================

-- 8. Team performance summary
SELECT
	t.team_name,
	COUNT(DISTINCT e.game_id) AS games,
	COUNT(*) AS total_events,
	COUNT(CASE WHEN e.event_type = 'goal' THEN 1 END) AS goals,
	COUNT(CASE WHEN e.event_type = 'shot' THEN 1 END) AS shots,
	COUNT(CASE WHEN e.event_type = 'penalty' THEN 1 END) AS penalties
FROM events e
JOIN teams t ON e.team_id = t.team_id
GROUP BY t.team_id, t.team_name
ORDER BY goals DESC;

-- 9. Team goals by period
SELECT
	t.team_name,
	e.period,
	COUNT(*) AS goals_in_period
FROM events e
JOIN teams t ON e.team_id = t.team_id
WHERE e.event_type = 'goal'
GROUP BY t.team_id, t.team_name, e.period
ORDER BY t.team_name, e.period;

-- ============================================================================
-- TIME-SERIES ANALYTICS
-- ============================================================================

-- 10. Events over time (hourly buckets)
SELECT
	DATE_TRUNC('hour', event_timestamp) AS hour,
	COUNT(*) AS events_count,
	COUNT(DISTINCT game_id) AS active_games
FROM events
WHERE event_timestamp >= NOW() - INTERVAL '7 days'
GROUP BY DATE_TRUNC('hour', event_timestamp)
ORDER BY hour DESC;

-- 11. Goals by time in period
SELECT
	SUBSTRING(game_time FROM 1 FOR 2) AS minute,
	period,
	COUNT(*) AS goals
FROM events
WHERE event_type = 'goal' AND game_time IS NOT NULL
GROUP BY SUBSTRING(game_time FROM 1 FOR 2), period
ORDER BY period, minute;

-- ============================================================================
-- CRAWLER OPERATIONS
-- ============================================================================

-- 12. Crawler performance summary
SELECT
	crawler_instance_id,
	crawler_version,
	COUNT(*) AS total_runs,
	COUNT(CASE WHEN status = 'SUCCESS' THEN 1 END) AS successful,
	COUNT(CASE WHEN status = 'FAILED' THEN 1 END) AS failed,
	AVG(duration_seconds) AS avg_duration,
	SUM(events_captured) AS total_events_captured,
	MAX(started_at) AS last_run
FROM crawler_runs
GROUP BY crawler_instance_id, crawler_version
ORDER BY last_run DESC;

-- 13. Recent crawler runs
SELECT
	cr.run_id,
	cr.crawler_instance_id,
	g.nhl_game_id,
	cr.started_at,
	cr.completed_at,
	cr.duration_seconds,
	cr.status,
	cr.events_captured
FROM crawler_runs cr
LEFT JOIN games g ON cr.game_id = g.game_id
ORDER BY cr.started_at DESC
LIMIT 20;

-- 14. Failed crawler runs
SELECT
	run_id,
	game_id,
	started_at,
	error_message,
	target_url
FROM crawler_runs
WHERE status = 'FAILED'
ORDER BY started_at DESC
LIMIT 10;

-- 15. Crawler capture latency
SELECT
	AVG(EXTRACT(EPOCH FROM (e.captured_at - e.event_timestamp))) AS avg_latency_seconds,
	MIN(EXTRACT(EPOCH FROM (e.captured_at - e.event_timestamp))) AS min_latency,
	MAX(EXTRACT(EPOCH FROM (e.captured_at - e.event_timestamp))) AS max_latency,
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (e.captured_at - e.event_timestamp))) AS median_latency
FROM events e
WHERE e.captured_at > NOW() - INTERVAL '24 hours';

-- ============================================================================
-- STREAMING & DATA LAKE
-- ============================================================================

-- 16. Events pending streaming
SELECT
	COUNT(*) AS pending_count,
	MIN(queued_at) AS oldest_queued,
	MAX(queued_at) AS newest_queued
FROM event_stream_queue
WHERE stream_status = 'PENDING';

-- 17. Streaming queue status
SELECT
	stream_status,
	COUNT(*) AS count,
	MIN(queued_at) AS oldest,
	MAX(queued_at) AS newest
FROM event_stream_queue
GROUP BY stream_status
ORDER BY count DESC;

-- 18. Failed streaming attempts
SELECT
	esq.queue_id,
	esq.event_id,
	esq.queued_at,
	esq.retry_count,
	esq.error_message
FROM event_stream_queue esq
WHERE stream_status = 'FAILED'
ORDER BY queued_at DESC
LIMIT 20;

-- 19. Mark events as processed (simulation)
-- UPDATE events
-- SET is_processed = TRUE, processed_at = NOW()
-- WHERE event_id IN (
-- 	SELECT event_id
-- 	FROM events
-- 	WHERE is_processed = FALSE
-- 	LIMIT 1000
-- );

-- ============================================================================
-- SYSTEM MONITORING
-- ============================================================================

-- 20. Database size by table
SELECT
	schemaname,
	tablename,
	pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
	pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
	pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS index_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- 21. Event counts by partition
SELECT
	schemaname,
	tablename,
	n_live_tup AS row_count,
	pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_stat_user_tables
WHERE tablename LIKE 'events_%'
ORDER BY n_live_tup DESC;

-- 22. Index usage statistics
SELECT
	schemaname,
	tablename,
	indexname,
	idx_scan AS times_used,
	idx_tup_read AS tuples_read,
	idx_tup_fetch AS tuples_fetched,
	pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan ASC;

-- 23. Most active tables
SELECT
	schemaname,
	tablename,
	seq_scan,
	seq_tup_read,
	idx_scan,
	idx_tup_fetch,
	n_tup_ins AS inserts,
	n_tup_upd AS updates,
	n_tup_del AS deletes
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY (n_tup_ins + n_tup_upd + n_tup_del) DESC;

-- ============================================================================
-- DATA QUALITY
-- ============================================================================

-- 24. Events with missing player references
SELECT
	event_type,
	COUNT(*) AS count_without_player
FROM events
WHERE player_id IS NULL
	AND event_type IN ('goal', 'shot', 'penalty')  -- Events that should have players
GROUP BY event_type;

-- 25. Games with event counts
SELECT
	g.game_id,
	g.nhl_game_id,
	g.game_date,
	g.game_status,
	COUNT(e.event_id) AS event_count,
	MIN(e.event_timestamp) AS first_event,
	MAX(e.event_timestamp) AS last_event
FROM games g
LEFT JOIN events e ON g.game_id = e.game_id
GROUP BY g.game_id, g.nhl_game_id, g.game_date, g.game_status
ORDER BY g.game_date DESC;

-- 26. Duplicate event detection
SELECT
	game_id,
	event_type,
	event_timestamp,
	game_time,
	period,
	player_id,
	COUNT(*) AS duplicate_count
FROM events
GROUP BY game_id, event_type, event_timestamp, game_time, period, player_id
HAVING COUNT(*) > 1;

