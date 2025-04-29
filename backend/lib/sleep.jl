module Sleep

using HTTP, JSON3, Dates, LibPQ, DataFrames, Dates
using ..Templates
import ..App
import ..Db


function insert_sleep_data(sleep_data::SleepData)
    conn = db.get_conn()
    q = """
        INSERT INTO sleep_data (
            date,
            location,
            room,
            twin_bed,
            sleep_solo,
            mouth_tape,
            nose_magnet,
            nose_magnet_off
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    """
    params = [
        sleep_data.date,
        sleep_data.location,
        sleep_data.room,
        sleep_data.twin_bed,
        sleep_data.sleep_solo,
        sleep_data.mouth_tape,
        sleep_data.nose_magnet,
        sleep_data.nose_magnet_off
    ]
    result = execute(conn, q, params)
    return result
end

struct SleepData
    date::Date
    location::String    
    room::String
    twin_bed::Bool
    sleep_solo::Bool
    mouth_tape::Bool
    nose_magnet::Bool
    nose_magnet_off::Bool

    function SleepData(data)
        @info "Creating sleep data"
        @info data
        date_str = get(data, "date", nothing)
        location = get(data, "location", nothing)
        room = get(data, "location", nothing)
        if date_str in [nothing, ""] || location in [nothing, ""] || room in [nothing, ""]
            ret = "Missing required data for sleep data"
            @error ret
            return false
        end

        twin_bed = get(data, "twin_bed", false)
        twin_bed = twin_bed == "on" ? true : false
        sleep_solo = get(data, "sleep_solo", false)
        sleep_solo = sleep_solo == "on" ? true : false
        mouth_tape = get(data, "mouth_tape", false)
        mouth_tape = mouth_tape == "on" ? true : false
        nose_magnet = get(data, "nose_magnet", false)
        nose_magnet = nose_magnet == "on" ? true : false
        nose_magnet_off = get(data, "nose_magnet_off", false)
        nose_magnet_off = nose_magnet_off == "on" ? true : false

        date = Date(date_str, "yyyy-mm-dd")
        if date > today()
            @error "Attempt to insert $date which is greater then $(today())"
            return false
        end

        obj = new(
            date,
            location,
            room,
            twin_bed,
            sleep_solo,
            mouth_tape,
            nose_magnet,
            nose_magnet_off
        )

        @info obj

        if result.status == LibPQ.ExecStatusType.COMMAND_OK
            @info "User inserted successfully."
            return true
        else
            @error "Failed to insert user: ", LibPQ.error_message(conn)
            return false
        end

    end
end

function serve_sleep_dashboard(req::HTTP.Request)
    html_path = joinpath(App.STATIC_DIR, "sleep/dashboard.html")
    wrap_return = wrap(html_path)
    if wrap_return.ok
        html_content = wrap_return.html
        return HTTP.Response(200, Dict("Content-Type" => "text/html"), html_content)
    end
    return HTTP.Response(501)
end

function get_sleep_list(req::HTTP.Request)
    conn = Db.get_conn()
    query = """SELECT * from sleep_data order by date desc;"""
    df = execute(conn, query) |> DataFrame
    HTTP.Response(200, App.get_headers(), JSON3.write(df))
end

function get_sleep_form(req::HTTP.Request)
    conn = Db.get_conn()
    query = """
        SELECT 
            column_name name, 
            data_type,
            column_default default, 
            is_nullable
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE table_name = 'sleep_data';
    """
    result = execute(conn, query)
    data = []
    for row in result
        row_dict = Dict{String,Any}()
        for (i, col) in enumerate(LibPQ.column_names(result))
            row_dict[col] = row[i]
        end
        push!(data, row_dict)
    end

    HTTP.Response(200, App.get_headers(), JSON3.write(data))
end

function create_sleep_data(req::HTTP.Request)
    body = JSON3.read(String(req.body))

    try
        #@info JSON3.read(body, SleepData)
        ok = SleepData(body)
        @info ok
    catch e
        @error "Caught: " e
        if e isa MethodError
            return HTTP.Response(400, "bad input")
        else
            return HTTP.Response(500)
        end
    end

    return HTTP.Response(200)
end

function get_missing_sleep_dates(req::HTTP.Request)
    conn = Db.get_conn()
    query = """SELECT * from sleep_data order by date desc;"""
    df = execute(conn, query) |> DataFrame
    HTTP.Response(200, App.get_headers(), JSON3.write(df))
end

function serve_sleep_form(req::HTTP.Request)
    html_path = joinpath(App.STATIC_DIR, "sleep/sleep_form.html")
    wrap_return = wrap(html_path)
    if wrap_return.ok
        html_content = wrap_return.html
        return HTTP.Response(200, Dict("Content-Type" => "text/html"), html_content)
    end
    return HTTP.Response(501)
end


HTTP.register!(App.ROUTER, "GET", "/sleep/dashboard", serve_sleep_dashboard)
HTTP.register!(App.ROUTER, "GET", "/sleep/list", get_sleep_list)
HTTP.register!(App.ROUTER, "POST", "/sleep/create", create_sleep_data)
HTTP.register!(App.ROUTER, "GET", "/sleep/form-data", get_sleep_form)
HTTP.register!(App.ROUTER, "GET", "/sleep/form", serve_sleep_form)
@info "sleep added to router"

end