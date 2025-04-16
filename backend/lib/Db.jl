module Db
export 
    get_enviro, 
    get_nasalspray, 
    get_activity, 
    get_sleep_data, 
    get_sleep, 
    get_recharge,
    get_config, 
    get_total_calories, 
    get_per_day,
    get_eat_sleep_score,
    get_conn,
    initialize,
    get_exercise,
    get_exercises

using LibPQ, DataFrames, JSON3, TOML, Dates

include("users.jl")
import .Users

include("exercises.jl")

function get_config()
    open("config.toml", "r") do io
        return TOML.parse(io)
    end
end


function get_conn()
    config = get_config()["db"]
    conn_str = """
        host=$(config["host"]) 
        port=$(config["port"])
        dbname=$(config["dbname"]) 
        user=$(config["user"]) 
        password=$(config["password"])
    """
    return LibPQ.Connection(conn_str)
end


function initialize()
    @info "Initializing DB"
    conn = get_conn()
    Users.create_users_table(conn)
    @info "Successfully initialized DB"
end


function get_conn_ha()
    config = get_config()["db"]
    conn_str = """
        host=$(config["host"]) 
        port=$(config["port"])
        dbname=homeassistant 
        user=$(config["user"]) 
        password=$(config["password"])
    """
    return LibPQ.Connection(conn_str)
end


function get_enviro()
    conn = get_conn()
    query = "SELECT * FROM enviro_plus ORDER BY timestamp;"
    df = execute(conn, query) |> DataFrame
    close(conn)
    return df
end

function get_enviro_recharge()
    conn = get_conn()
    query = """
        SELECT 
            r.heart_rate_avg,
            r.beat_to_beat_avg,
            r.heart_rate_variability_avg,
            r.breathing_rate_avg,
            r.nightly_recharge_status,
            r.ans_charge,
            AVG(e.temperature) avg_temperature, 
            MIN(e.temperature) min_temperature, 
            MAX(e.temperature) max_temperature,
            VARIANCE(e.temperature) var_temperature,
            AVG(e.pressure) avg_pressure,
            MIN(e.pressure) min_pressure,
            MAX(e.pressure) max_pressure,
            VARIANCE(e.pressure) var_pressure,
            AVG(e.humidity) avg_humidity,
            MIN(e.humidity) min_humidity,
            MAX(e.humidity) max_humidity,
            VARIANCE(e.humidity) var_humidity,
            AVG(e.oxidised) avg_oxidised,
            MIN(e.oxidised) min_oxidised,
            MAX(e.oxidised) max_oxidised,
            VARIANCE(e.oxidised) var_oxidised,
            AVG(e.reduced) avg_reduced,
            MIN(e.reduced) min_reduced,
            MAX(e.reduced) max_reduced,
            VARIANCE(e.reduced) var_reduced,
            AVG(e.nh3) avg_nh3,
            MIN(e.nh3) min_nh3,
            MAX(e.nh3) max_nh3,
            VARIANCE(e.nh3) var_nh3,
            AVG(e.lux) avg_lux,
            MIN(e.lux) min_lux,
            MAX(e.lux) max_lux,
            VARIANCE(e.lux) var_lux
        FROM sleep s 
        FULL JOIN polar_recharge r 
            ON r.date = date(s.sleep_end_time)
        LEFT JOIN enviro_plus e 
            ON e.timestamp 
            BETWEEN s.sleep_start_time AND s.sleep_end_time 
        GROUP BY 
            r.heart_rate_avg,
            r.beat_to_beat_avg,
            r.heart_rate_variability_avg,
            r.breathing_rate_avg,
            r.nightly_recharge_status,
            r.ans_charge;
    """
    df = execute(conn, query) |> DataFrame
    close(conn)
    return df
end


function get_enviro_sleep()
    conn = get_conn()
    query = """
        SELECT 
            s.sleep_start_time, 
            s.sleep_end_time, 
            s.sleep_score,
            s.sleep_charge,
            AVG(e.temperature) avg_temperature, 
            MIN(e.temperature) min_temperature, 
            MAX(e.temperature) max_temperature,
            VARIANCE(e.temperature) var_temperature,
            AVG(e.pressure) avg_pressure,
            MIN(e.pressure) min_pressure,
            MAX(e.pressure) max_pressure,
            VARIANCE(e.pressure) var_pressure,
            AVG(e.humidity) avg_humidity,
            MIN(e.humidity) min_humidity,
            MAX(e.humidity) max_humidity,
            VARIANCE(e.humidity) var_humidity,
            AVG(e.oxidised) avg_oxidised,
            MIN(e.oxidised) min_oxidised,
            MAX(e.oxidised) max_oxidised,
            VARIANCE(e.oxidised) var_oxidised,
            AVG(e.reduced) avg_reduced,
            MIN(e.reduced) min_reduced,
            MAX(e.reduced) max_reduced,
            VARIANCE(e.reduced) var_reduced,
            AVG(e.nh3) avg_nh3,
            MIN(e.nh3) min_nh3,
            MAX(e.nh3) max_nh3,
            VARIANCE(e.nh3) var_nh3,
            AVG(e.lux) avg_lux,
            MIN(e.lux) min_lux,
            MAX(e.lux) max_lux,
            VARIANCE(e.lux) var_lux
        FROM sleep s 
        LEFT JOIN enviro_plus e 
            ON e.timestamp 
            BETWEEN s.sleep_start_time AND s.sleep_end_time 
        GROUP BY 
            s.sleep_start_time, 
            s.sleep_end_time,
            s.sleep_score,
            s.sleep_charge
    """
    df = execute(conn, query) |> DataFrame
    close(conn)
    return df
end


function get_nasalspray()
    conn = get_conn()
    query = "SELECT * FROM nasalspray ORDER BY timestamp;"
    #return execute(conn, query) |> DataFrame
    data = execute(conn, query)
    close(conn)
    return data
end


function get_activity()
    conn = get_conn()
    query = "SELECT * FROM activity ORDER BY date;"
    return execute(conn, query) |> DataFrame
end


function get_exercises_tcx()
    conn = get_conn()
    query = """
        SELECT 
            start_time,
            distance,
            hr_avg,
            hr_max,
            hr_min,
            duration,
            sport_type,
            calories,
            ascent,
            descent
        FROM exercises_tcx 
        ORDER BY start_time;
    """
    df = execute(conn, query) |> DataFrame
end


function get_sleep_data()
    conn = get_conn()
    query = """SELECT * FROM sleep_data ORDER BY date;"""
    df = execute(conn, query) |> DataFrame
    df.date = Date.(df.date)
    close(conn)
    return df
end


function get_sleep()
    conn = get_conn()
    query = """
        SELECT 
            s.*,
            avg(hr.heart_rate) avg_sleep_heart_rate
        FROM sleep s
        LEFT JOIN sleep_heart_rate hr
        ON hr.sleep_id = s.id
        GROUP BY s.id
        ORDER BY date
    """
    df = execute(conn, query) |> DataFrame
    #df = JSON3.read.(temp_df.data) |> DataFrame
    #df.date = Date.(df.date)
    close(conn)
    return df
end


function get_recharge()
    conn = get_conn()
    query = """
        SELECT
            date, 
            beat_to_beat_avg, 
            heart_rate_variability_avg, 
            breathing_rate_avg,
            nightly_recharge_status, 
            ans_charge, 
            ans_charge_status
        FROM polar_recharge
        ORDER BY date
    """
    df = execute(conn, query) |> DataFrame
    close(conn)
    return df
end


function get_food(ts_from, ts_to)
    conn = get_conn()
    query = """
        SELECT 
            f.calories, 
            c.amount, 
            c.dateeaten 
        FROM consumed c 
        LEFT JOIN food f 
        ON f.id = c.food
        WHERE c.dateeaten between $(1) AND $(2)
        ORDER BY c.dateeaten;
    """
    df = execute(conn, query, [from, to]) |> DataFrame
    close(conn)
    return df
end


function get_total_calories()
    conn = get_conn()
    query = """select sum(c.amount*f.calories/100) from consumed c left join food f on f.id = c.food;"""
    temp_df = execute(conn, query) |> DataFrame
    close(conn)
    return temp_df.sum[1]
end


function get_food_per_day()
    conn = get_conn()
    query = """
        SELECT 
            date(c.dateeaten) as date, 
            sum(f.calories*c.amount/100) as calories,
            sum(f.fat*c.amount/100) as fat,
            sum(f.carbs*c.amount/100) as carbs,
            sum(f.protein*c.amount/100) as proteins,
            sum(f.salt*c.amount/100) as salt,
            sum(f.sugar*c.amount/100) sugar,
            sum(f.starch*c.amount/100) as starch,
            sum(f.fiber*c.amount/100) as fiber,
            sum(f.vitamina*c.amount/100) as vitamin_A,
            sum(f.vitaminb1*c.amount/100) as vitamin_b1,
            sum(f.vitaminb2*c.amount/100) as vitamin_b2,
            sum(f.vitaminb3*c.amount/100) as vitamin_b3,
            sum(f.vitaminb5*c.amount/100) as vitamin_b5,
            sum(f.vitaminb6*c.amount/100) as vitamin_b6,
            sum(f.vitaminb7*c.amount/100) as vitamin_b7,
            sum(f.vitaminb9*c.amount/100) as vitamin_b9,
            sum(f.vitaminb12*c.amount/100) as vitamin_b12,
            sum(f.vitamind*c.amount/100) as vitamin_d,
            sum(f.vitamine*c.amount/100) as vitamin_e,
            sum(f.calcium*c.amount/100) as calcium,
            sum(f.chloride*c.amount/100) as chloride,
            sum(f.magnesium*c.amount/100) as magnesium,
            sum(f.phosphorus*c.amount/100) as phosphorous,
            sum(f.potassium*c.amount/100) as kalium,
            sum(f.sodium*c.amount/100) as natrium,
            sum(f.chromium*c.amount/100) as chromium,
            sum(f.iron*c.amount/100) as iron,
            sum(f.fluorine*c.amount/100) as fluorine,
            sum(f.iodine*c.amount/100) as iodine,
            sum(f.copper*c.amount/100) as copper,
            sum(f.manganese*c.amount/100) as manganese,
            sum(f.molybdenum*c.amount/100) as molybdenum,
            sum(f.selenium*c.amount/100) as selenium,
            sum(f.zinc*c.amount/100) as zinc,
            sum(f.monounsaturatedfat*c.amount/100) as monounsaturatedfat,
            sum(f.polyunsaturatedfat*c.amount/100) as polyunsaturatedfat,
            sum(f.omega3*c.amount/100) as omega3,
            sum(f.omega6*c.amount/100) as omega6,
            sum(f.saturatedfat*c.amount/100) as saturatedfat,
            sum(f.transfat*c.amount/100) as transfat,
            sum(f.cholesterol*c.amount/100) as cholesterol,
            sum(f.sugaralcohol*c.amount/100) as sugaralcohol,
            sum(f.water*c.amount/100) as water,
            sum(f.caffeine*c.amount/100) as caffeine,
            sum(f.alcohol*c.amount/100) as alcohol
        FROM consumed c 
        LEFT JOIN food f ON f.id = c.food
        GROUP BY date ORDER BY date DESC;
    """
    df = execute(conn, query) |> DataFrame
    close(conn)
    df = coalesce.(df, 0.0)
    return df
end


function get_per_meal()
    conn = get_conn()
    query = """
        SELECT 
            (c.dateeaten - interval '15 minutes') as start_eat, 
            (c.dateeaten + interval '15 minutes') as stop_eat, 
            sum(f.calories*c.amount/100) as calories,
            sum(f.fat*c.amount/100) as fat,
            sum(f.carbs*c.amount/100) as carbs,
            sum(f.protein*c.amount/100) as proteins,
            sum(f.salt*c.amount/100) as salt,
            sum(f.sugar*c.amount/100) sugar,
            sum(f.starch*c.amount/100) as starch,
            sum(f.fiber*c.amount/100) as fiber
        FROM consumed c 
        LEFT JOIN food f ON f.id = c.food 
        GROUP BY dateeaten ORDER BY c.dateeaten DESC;
    """
    df = execute(conn, query) |> DataFrame
    close(conn)
    df = coalesce.(df, 0.0)
    return df

end


function get_latlon()
    # olas iphone device_tracker is metadataid 173
    conn = get_conn_ha()
    query = """
    	SELECT 
	    s.last_updated_ts, 
	    a.shared_attrs 
	FROM states s 
	INNER JOIN state_attributes a ON a.attributes_id = s.attributes_id  
	WHERE metadata_id = 173 
	LIMIT 5
    """
    result = execute(conn, query)
    close(conn)
    for row in result
        ts = row[1]
        json_obj = JSON3.read(String(row[2]))
        return json_obj
    end
end


function get_averages()
    conn = get_conn_ha()
    query = "SELECT AVG(steps) FROM activity;"
    steps = first(fetch(execute(conn, query)))[1]
    query = "SELECT AVG(heart_rate) from sleep_heart_rate;"
    sleep_hr = execute(query) |> DataFrame


end


function get_sleep_hr()
    conn = get_conn()
    query = """
        SELECT 
        heart_rate.key AS time,
        heart_rate.value::INT AS heart_rate_value
        FROM 
        sleep,
        LATERAL jsonb_each_text(data->'heart_rate_samples') AS heart_rate;
    """
    result = execute(conn, query)
    timestamps = String[]
    heart_rates = Int[]

    for row in result
        push!(timestamps, row[1])  # Add timestamp
        push!(heart_rates, row[2]) # Add heart rate value
    end

    json_result = Dict("timestamps" => timestamps, "heart_rates" => heart_rates)
    json_output = JSON3.write(json_result)

    return json_output
end


function get_sleep_json()
    conn = get_conn()
    query = """
        SELECT data FROM sleep;
    """
    result = execute(conn, query)
    nights = []
    for row in result
        json_data_str = row[1]
        json_data = JSON3.read(json_data_str)
        push!(nights, json_data)
    end
    return nights
end


function get_eat_sleep_score()
    """
    WIP: Take all food eaten and subtract a number proportional to the dt between dateeaten and sleep_start_time
    """
    conn = get_conn()

    query = """
    SELECT
        GREATEST(sum(f.calories*c.amount/100) / EXTRACT(EPOCH FROM (sleep_start_time - dateeaten)), 0) eat_sleep_score, 
        s.date
    FROM 
        consumed c 
    JOIN food f ON f.id = c.food 
    JOIN sleep s ON s.date = c.dateeaten::date + INTERVAL '1 day' 
    GROUP BY s.date, sleep_start_time, dateeaten
    ORDER BY s.date;
    """
    df = execute(conn, query) |> DataFrame
    close(conn)
    combine(groupby(df, :date), :eat_sleep_score => sum => :daily_eat_sleep_score)
end


function get_sleep_quality()
    q = """
        SELECT 
            DISTINCT sd.date, 
            saa.tracking_start, 
            saa.tracking_end, 
            saa.snore, 
            saa.rating, 
            sd.nose_magnet,
            s.sleep_charge,
            s.sleep_start_time sleep_start,
            s.sleep_end_time sleep_end,
            s.sleep_score,
            s.sleep_rating 
        FROM sleep_as_android saa 
        INNER JOIN sleep_data sd 
            ON sd.date = date(saa.tracking_end) 
        LEFT JOIN sleep s
            ON s.date = sd.date
        ORDER BY sd.date desc;
    """
    conn = get_conn()
    df = execute(conn, q) |> DataFrame
    close(conn)
    return df
end

end