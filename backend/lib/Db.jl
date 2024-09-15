module Db
export get_enviro, get_nasalspray, get_activity, get_sleep_data, get_sleep, get_config, get_total_calories, get_per_day
using LibPQ, DataFrames, JSON3, TOML, Dates


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
    close(conn)
    return execute(conn, query) |> DataFrame
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
    query = """SELECT * FROM sleep ORDER BY date"""
    df = execute(conn, query) |> DataFrame
    #df = JSON3.read.(temp_df.data) |> DataFrame
    #df.date = Date.(df.date)
    close(conn)
    return df
end


function get_food()
    conn = get_conn()
    query = "select f.*, c.amount, c.dateeaten from consumed c left join food f on f.id = c.food order by c.dateeaten;"
    df = execute(conn, query) |> DataFrame
    df = coalesce.(df, 0.0)
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


function get_per_day()
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
            sum(f.fiber*c.amount/100) as fiber
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
    query = """
        SELECT AVG)
    """

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

end