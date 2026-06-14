CREATE INDEX IF NOT EXISTS idx_trips_utc_start_datetime ON trips (utc_start_datetime);
CREATE INDEX IF NOT EXISTS idx_trips_type ON trips (type);
CREATE INDEX IF NOT EXISTS idx_trips_operator ON trips (operator);
CREATE INDEX IF NOT EXISTS idx_trips_start_datetime ON trips (start_datetime);
CREATE INDEX IF NOT EXISTS idx_trips_end_datetime ON trips (end_datetime);
CREATE INDEX IF NOT EXISTS idx_trips_last_modified ON trips (last_modified)
