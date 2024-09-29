q1 = """
    CREATE TABLE if not exists polar_recharge (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        polar_user VARCHAR(255),
        date DATE unique,
        heart_rate_avg INTEGER,
        beat_to_beat_avg INTEGER,
        heart_rate_variability_avg INTEGER,
        breathing_rate_avg NUMERIC,
        nightly_recharge_status INTEGER,
        ans_charge NUMERIC,
        ans_charge_status INTEGER
    );
"""

q2 = """
    CREATE TABLE if not exists polar_hrv_samples (
        recharge_id INTEGER REFERENCES polar_recharge(id) ON DELETE CASCADE,
        time TIME,
        hrv INTEGER,
        UNIQUE (recharge_id, time)
    )
"""

q3 = """
    CREATE TABLE if not exists polar_breathing_samples (
        recharge_id INTEGER REFERENCES polar_recharge(id) ON DELETE CASCADE,
        time TIME,
        breathing_rate NUMERIC,
        UNIQUE (recharge_id, time)
    )
"""

q4 = """
    INSERT INTO polar_recharge (
        polar_user, date, heart_rate_avg, beat_to_beat_avg, 
        heart_rate_variability_avg, breathing_rate_avg, 
        nightly_recharge_status, ans_charge, ans_charge_status
    )
    SELECT
        data->>'polar_user',
        (data->>'date')::date,
        (data->>'heart_rate_avg')::int,
        (data->>'beat_to_beat_avg')::int,
        (data->>'heart_rate_variability_avg')::int,
        (data->>'breathing_rate_avg')::numeric,
        (data->>'nightly_recharge_status')::int,
        (data->>'ans_charge')::numeric,
        (data->>'ans_charge_status')::int
    FROM recharge;
"""

q5 = """
    WITH main AS (
        SELECT
            pr.id as pr_id,
            r.data->'hrv_samples' as hrv_data
        FROM recharge r
        JOIN polar_recharge pr ON r.date = pr.date
    )
    INSERT INTO polar_hrv_samples (recharge_id, time, hrv)
    SELECT
        main.pr_id,
        key::time,
        value::int
    FROM main, jsonb_each_text(main.hrv_data)
    ON CONFLICT do nothing;
"""


q6 = """
    WITH main AS (
        SELECT
            pr.id as pr_id,
            r.data->'hrv_samples' as breathing_data
        FROM recharge r
        JOIN polar_recharge pr ON r.date = pr.date
    )
    INSERT INTO polar_breathing_samples (recharge_id, time, breathing_rate)
    SELECT
        main.pr_id,
        key::time,
        value::int
    FROM main, jsonb_each_text(main.breathing_data)
    ON CONFLICT do nothing;
"""