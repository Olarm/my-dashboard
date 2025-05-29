module Weights

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


struct Weight
    timestamp::ZonedDateTime
    weight::Float64

    function Weight(data)
        iso_string = get(data, "timestamp", nothing)
        if iso_string == nothing
            return (ok=false, data=nothing)
        end
        dt_format = DateFormat("yyyy-mm-dd HH:MM:SSzzzz")
        zdt = ZonedDateTime(iso_string, dt_format)

        weight_string = get(data, "weight", nothing)
        if weight_string == nothing
            return (ok=false, data=nothing)
        end
        weight = parse(Float64, weight_string)

        obj = new(zdt, weight)
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
            weight DOUBLE PRECISION NOT NULL,
            unique(user_id, timestamp)
        );
    """
    execute(conn, q)
    close(conn)
    return true
end

function create_weight(weight::Weight, user::Users.User)
    conn = Db.get_conn()
    q = """
        INSERT INTO weight (user_id, timestamp, weight)
        VALUES (\$1, \$2, \$3)
        ON CONFLICT do nothing
    """
    execute(conn, q, [user.id, weight.timestamp, weight.weight])
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
    return HTTP.Response(200, App.get_headers(), JSON3.write(weight_result.data))
end

HTTP.register!(App.ROUTER, "POST", "/weight/create", post_weight)
end