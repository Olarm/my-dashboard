
q1 = """
    CREATE TABLE if not exists sleep (
        id SERIAL PRIMARY KEY,
        polar_user VARCHAR(255),
        date DATE unique,
        sleep_start_time TIMESTAMPTZ,
        sleep_end_time TIMESTAMPTZ,
        device_id VARCHAR(50),
        continuity NUMERIC,
        continuity_class INTEGER,
        light_sleep INTEGER,
        deep_sleep INTEGER,
        rem_sleep INTEGER,
        unrecognized_sleep_stage INTEGER,
        sleep_score INTEGER,
        total_interruption_duration INTEGER,
        sleep_charge INTEGER,
        sleep_goal INTEGER,
        sleep_rating INTEGER,
        short_interruption_duration INTEGER,
        long_interruption_duration INTEGER,
        sleep_cycles INTEGER,
        group_duration_score NUMERIC,
        group_solidity_score NUMERIC,
        group_regeneration_score NUMERIC
    );
    """

q2 = """
CREATE TABLE hypnogram (
    sleep_id INTEGER REFERENCES sleep(id) ON DELETE CASCADE,
    time TIME,
    stage INTEGER,
    UNIQUE (sleep_id, time)
);
"""

q3 = """
CREATE TABLE sleep_heart_rate (
    sleep_id INTEGER REFERENCES sleep(id) ON DELETE CASCADE,
    time TIME,
    heart_rate INTEGER,
    UNIQUE (sleep_id, time)
);
"""

q4 = """
INSERT INTO sleep (
    polar_user, date, sleep_start_time, sleep_end_time, device_id, continuity, 
    continuity_class, light_sleep, deep_sleep, rem_sleep, unrecognized_sleep_stage, 
    sleep_score, total_interruption_duration, sleep_charge, sleep_goal, sleep_rating, 
    short_interruption_duration, long_interruption_duration, sleep_cycles, 
    group_duration_score, group_solidity_score, group_regeneration_score
)
SELECT
    data->>'polar_user',
    (data->>'date')::date,
    (data->>'sleep_start_time')::timestamptz,
    (data->>'sleep_end_time')::timestamptz,
    data->>'device_id',
    (data->>'continuity')::numeric,
    (data->>'continuity_class')::int,
    (data->>'light_sleep')::int,
    (data->>'deep_sleep')::int,
    (data->>'rem_sleep')::int,
    (data->>'unrecognized_sleep_stage')::int,
    (data->>'sleep_score')::int,
    (data->>'total_interruption_duration')::int,
    (data->>'sleep_charge')::int,
    (data->>'sleep_goal')::int,
    (data->>'sleep_rating')::int,
    (data->>'short_interruption_duration')::int,
    (data->>'long_interruption_duration')::int,
    (data->>'sleep_cycles')::int,
    (data->>'group_duration_score')::numeric,
    (data->>'group_solidity_score')::numeric,
    (data->>'group_regeneration_score')::numeric
FROM sleep_old;
"""

q5 = """
WITH main AS (
    SELECT
        sleep.id as sleep_id,
        sleep_old.data->'hypnogram' AS hypnogram_data
    FROM sleep_old
    JOIN sleep ON sleep.date = (sleep_old.data->>'date')::date
)
INSERT INTO hypnogram (sleep_id, time, stage)
SELECT
    main.sleep_id,
    key::time,                   -- Extract and insert time from hypnogram object
    value::int                   -- Extract and insert stage from hypnogram object
FROM main, jsonb_each_text(main.hypnogram_data)
ON CONFLICT (sleep_id, time) DO NOTHING; -- Handle duplicates by ignoring
"""

q6 = """
WITH main AS (
    SELECT 
        sleep.id as sleep_id, 
        sleep_old.data->'heart_rate_samples' as heart_rate_samples
    FROM sleep_old
    JOIN sleep ON sleep.date = (sleep_old.data->>'date')::date
)
INSERT INTO sleep_heart_rate (sleep_id, time, heart_rate)
SELECT
    main.sleep_id,
    key::time,
    value::int
FROM main, jsonb_each_text(main.heart_rate_samples);
"""