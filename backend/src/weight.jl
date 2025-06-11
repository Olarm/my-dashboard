module Weights

using 
    HTTP, 
    JSON3, 
    Dates,
    TimeZones, 
    LibPQ,
    DataFrames

using ..Templates
import ..FeedbackLoop
import ..Db
import ..Users


struct Weight
    timestamp::ZonedDateTime
    timestamp_timezone::String
    weight::Float64

    function Weight(data)
        iso_string = get(data, "timestamp", nothing)
        if iso_string == nothing
            return (ok=false, data=nothing)
        end
        dt_format = DateFormat("yyyy-mm-dd HH:MM:SSzzzz")
        zdt = ZonedDateTime(iso_string, dt_format)

        timezone = get(data, "timestamp_timezone", nothing)
        if timezone == nothing
            return (ok=false, data=nothing)
        end

        weight_string = get(data, "weight", nothing)
        if weight_string == nothing
            return (ok=false, data=nothing)
        end
        weight = parse(Float64, weight_string)

        obj = new(zdt, timezone, weight)
        return (ok=true, data=obj)
    end
end

function create_weight_tables()
    conn = Db.get_conn()
    q = """
        CREATE TABLE IF NOT EXISTS weight (
            id SERIAL PRIMARY KEY,
            user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
            timestamp_timezone TEXT NOT NULL,
            weight DOUBLE PRECISION NOT NULL,
            unique(user_id, timestamp)
        );
    """
    execute(conn, q)
    close(conn)
    return true
end

function get_weight(n, user_id)
    conn = Db.get_conn()
    q = """
        SELECT 
            timestamp,
            timestamp_timezone,
            weight 
        FROM weight
        ORDER BY timestamp DESC
        LIMIT \$1
    """
    df = execute(conn, q, [n]) |> DataFrame
    close(conn)
    dropmissing!(df)
    for row in eachrow(df)
        tz = TimeZone(row.timestamp_timezone, TimeZones.Class(:LEGACY))
        row.timestamp = astimezone(row.timestamp, tz)
    end
    select!(df, Not([:timestamp_timezone]))
    return df
end

function create_weight(weight::Weight, user::Users.User)
    @info "Creating weight: " weight
    conn = Db.get_conn()
    q = """
        INSERT INTO weight (user_id, timestamp, timestamp_timezone, weight)
        VALUES (\$1, \$2, \$3, \$4)
        ON CONFLICT do nothing
    """
    execute(conn, q, [user.id, weight.timestamp, weight.timestamp_timezone, weight.weight])
    close(conn)
    return true
end

function post_weight(req::HTTP.Request)
    body = JSON3.read(String(req.body))
    @info body
    weight_result = Weight(body)
    if !weight_result.ok
        @error "Failed to create weight data."
        return HTTP.Response(400, JSON3.write("bad input"))
    end

    user = req.context[:user]
    result = create_weight(weight_result.data, user)
    if result == true
        @info "Weight inserted successfully."
    else
        @error "Failed to insert weight data."
        return HTTP.Response(400, JSON3.write("bad input"))
    end

    return_data = get_weight(1, user.id)
    return_row = Templates.create_table_rows(return_data)
    data = Dict("insertedRow" => return_row)

    return HTTP.Response(200, FeedbackLoop.get_headers(), JSON3.write(data))
end

HTTP.register!(FeedbackLoop.ROUTER, "POST", "/weight/create", post_weight)
end