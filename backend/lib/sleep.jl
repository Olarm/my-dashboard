module Sleep

using HTTP, JSON3, Dates, LibPQ, DataFrames
using ..Templates
import ..App
import ..Db


struct SleepData
    date::Date
    location::String    
    room::String
    twin_bed::Bool
    sleep_solo::Bool
    mouth_tape::Bool
    nose_magnet::Bool
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
    query = """SELECT * from sleep_data order by date desc;"""
    df = execute(conn, query) |> DataFrame
    HTTP.Response(200, App.get_headers(), JSON3.write(df))
end

function create_sleep_data(req::HTTP.Request)
    @info "create sleep"
    data = try
        JSON3.read(req.body)
    catch e
        if e isa MethodError
            return HTTP.Response(400, "bad input")
        else
            return HTTP.Response(500)
        end
    end

    @info data
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
@info "sleep added to router"

end