module Bsss

using 
    HTTP, 
    JSON3, 
    Dates,
    TimeZones, 
    LibPQ,
    DataFrames

using ..Templates
import ..App
import ..Db
import ..Forms
import ..Users


struct Bss
    timestamp::ZonedDateTime
    timestamp_timezone::String
    score::Int
    secondary::Union{Nothing, Int}

    function Bss(data)
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

        bss_string = get(data, "score", nothing)
        if bss_string == nothing
            return (ok=false, data=nothing)
        end
        bss = parse(Int, bss_string)

        secondary_string = get(data, "secondary_score", nothing)
        secondary_string = strip(secondary_string)
        secondary = nothing
        if isa(secondary_string, SubString)
            secondary = parse(Int, secondary_string)
        end

        obj = new(zdt, timezone, bss, secondary)
        return (ok=true, data=obj)
    end
end

function create_bss_tables()
    conn = Db.get_conn()
    q = """
        CREATE TABLE IF NOT EXISTS bss (
            id SERIAL PRIMARY KEY,
            user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
            timestamp_timezone TEXT NOT NULL,
            score INT NOT NULL CONSTRAINT valid_score CHECK (score BETWEEN 1 AND 7),
            secondary_score INT CONSTRAINT valid_secondary_score CHECK (score BETWEEN 1 AND 7),
            unique(user_id, timestamp)
        );
    """
    execute(conn, q)
    close(conn)
    return true
end

function get_bss(n, user_id)
    conn = Db.get_conn()
    q = """
        SELECT 
            timestamp,
            timestamp_timezone,
            score,
            secondary_score
        FROM bss
        WHERE user_id = \$1
        ORDER BY timestamp DESC
        LIMIT \$2
    """
    df = execute(conn, q, [user_id, n]) |> DataFrame
    close(conn)
    for row in eachrow(df)
        tz = TimeZone(row.timestamp_timezone, TimeZones.Class(:LEGACY))
        row.timestamp = astimezone(row.timestamp, tz)
    end
    select!(df, Not([:timestamp_timezone]))
    return df
end

function create_bss(bss::Bss, user::Users.User)
    conn = Db.get_conn()
    if bss.secondary != nothing
        q = """
            INSERT INTO bss (user_id, timestamp, timestamp_timezone, score, secondary_score)
            VALUES (\$1, \$2, \$3, \$4, \$5)
            ON CONFLICT do nothing
        """
        execute(conn, q, [user.id, bss.timestamp, bss.timestamp_timezone, bss.score, bss.secondary])
    else
        q = """
            INSERT INTO bss (user_id, timestamp, timestamp_timezone, score)
            VALUES (\$1, \$2, \$3, \$4)
            ON CONFLICT do nothing
        """
        execute(conn, q, [user.id, bss.timestamp, bss.timestamp_timezone, bss.score])
    end
    close(conn)
    return true
end

function post_bss(req::HTTP.Request)
    body = JSON3.read(String(req.body))
    bss_result = Bss(body)
    if !bss_result.ok
        @error "Failed to create BSS data with data: $body"
        return HTTP.Response(400, JSON3.write("bad input"))
    end

    user = req.context[:user]
    result = create_bss(bss_result.data, user)
    if result != true
        @error "Failed to insert BSS data with object: $bss_result"
        return HTTP.Response(400, JSON3.write("bad input"))
    end

    return_data = get_bss(1, user.id)
    return_row = Templates.create_table_rows(return_data)
    data = Dict("insertedRow" => return_row)

    return HTTP.Response(200, App.get_headers(), JSON3.write(data))
end

HTTP.register!(App.ROUTER, "POST", "/bss/create", post_bss)
end