module App
using HTTP, JSON3, StructTypes, LibPQ, Sockets, Tables

include("lib/Db.jl")
include("lib/food.jl")

#using Main.SleepAnalysis
using .Db
using .Food
#using Main.StatisticAnalysis


const STATIC_DIR = joinpath(@__DIR__, "frontend")


function parse_auth(req)
    @info req
    return true
end

function get_headers()
    return Dict(
        "Access-Control-Allow-Origin" => "*",         # Allow requests from any origin
        "Access-Control-Allow-Methods" => "GET",      # Allow only GET requests
        "Access-Control-Allow-Headers" => "Content-Type", # Allow the Content-Type header
        "Content-Type" => "application/json"          # Ensure response is JSON
    )
end

function JSON_middleware(handler)
    # Middleware functions return *Handler* functions
    return function(req::HTTP.Request)
        # first check if there's any request body
        if isempty(req.body)
            # we slightly change the Handler interface here because we know
            # our handler methods will either return nothing or an Animal instance
            ret = handler(req)
        else
            # replace request body with parsed Animal instance
            req.body = JSON3.read(req.body, Animal)
            ret = handler(req)
        end
        
        # return a Response, if its a response already (from 404 and 405 handlers)
        if ret isa HTTP.Response
            return ret
        else # otherwise serialize any Animal as json string and wrap it in Response
            return HTTP.Response(200, CORS_RES_HEADERS, ret === nothing ? "" : JSON3.write(ret))
        end
    end
end

# authentication middleware to ensure property security
function auth_middleware(handler)
    @info "auth middleware"
    return function(req)
        ident = parse_auth(req)
        if ident === nothing
            # failed to security authentication
            return HTTP.Response(401, "unauthorized")
        else
            # store parsed identity in request context for handler usage
            req.context[:auth] = ident
            # pass request on to handler function for further processing
            return handler(req)
        end
    end
end

function get_tcx_table(req)
    path = joinpath(STATIC_DIR, "tcx_table.html")
    html_content = read(path, String)

    return HTTP.Response(200, Dict("Content-Type" => "text/html"), html_content)
end

function get_map(req)
    path = joinpath(STATIC_DIR, "map.html")
    html_content = read(path, String)

    return HTTP.Response(200, Dict("Content-Type" => "text/html"), html_content)

end

function get_trip(req)
    data = get_exercise()
    @info "got exercise"

    HTTP.Response(200, get_headers(), data)
end

function get_trips(req)
    data = get_exercises()
    @info "got exercises"

    HTTP.Response(200, get_headers(), JSON3.write(data))
end

function get_tcx_list(req)
    data = Db.get_exercises_tcx()
    HTTP.Response(200, get_headers(), JSON3.write(data))
end

function get_dashboard(req)
    @info "GOT Request"
    path = joinpath(STATIC_DIR, "index.html")
    html_content = read(path, String)
    return HTTP.Response(200, Dict("Content-Type" => "text/html"), html_content)
end

function get_food_table(req)
    path = joinpath(STATIC_DIR, "food_table.html")
    html_content = read(path, String)
    return HTTP.Response(200, Dict("Content-Type" => "text/html"), html_content)
end


function get_daily_food(req)
    data = Db.get_food_per_day()
    HTTP.Response(200, get_headers(), JSON3.write(data))
end


function get_activity(req)
    df = Db.get_activity()
    data = Dict("name" => "Julia", "language" => "Julia", "dates" => df.date, "steps" => df.steps)
    HTTP.Response(200, get_headers(), JSON3.write(data))
end

function get_calories(req)
    @info "getting data"
    df = Food.calories_in_out()
    data = Tables.columntable(df)
    HTTP.Response(200, get_headers(), JSON3.write(data))
end

function get_nasalspray(req)
    return HTTP.Response(200, "hello")
end

function get_mime_type(file_path::String)
    ext = splitext(file_path)[2]
    mime_types = Dict(
        ".css" => "text/css",
        ".html" => "text/html",
        ".js" => "application/javascript",
        ".png" => "image/png",
        ".jpg" => "image/jpeg",
        ".svg" => "image/svg+xml"
    )
    get(mime_types, ext, "application/octet-stream")
end

function serve_static_file(req::HTTP.Request)
    relative_path = replace(String(req.target), "/static/" => "static/")
    file_path = joinpath(STATIC_DIR, relative_path)
    
    if isfile(file_path)
        mime_type = get_mime_type(file_path)
        content = read(file_path)
        return HTTP.Response(200, Dict("Content-Type" => mime_type), content)
    else
        @warn "File not found: $(file_path)"
        return HTTP.Response(404, "File not found.")
    end
end


initialize()

const ROUTER = HTTP.Router()
#HTTP.register!(ROUTER, "GET", "/api/nasalspray", get_nasalspray)
HTTP.register!(ROUTER, "GET", "/activity", get_activity)
HTTP.register!(ROUTER, "GET", "/calories", get_calories)
HTTP.register!(ROUTER, "GET", "/dashboard", get_dashboard)
HTTP.register!(ROUTER, "GET", "/map", get_map)
HTTP.register!(ROUTER, "GET", "/tcx_table", get_tcx_table)
HTTP.register!(ROUTER, "GET", "/trip", get_trip)
HTTP.register!(ROUTER, "GET", "/trips", get_trips)
HTTP.register!(ROUTER, "GET", "/tcx", get_tcx_list)
HTTP.register!(ROUTER, "GET", "/food_table", get_food_table)
HTTP.register!(ROUTER, "GET", "/food_list", get_daily_food)
HTTP.register!(ROUTER, "GET", "/static/*", serve_static_file)


#HTTP.serve(ROUTER |> auth_middleware, Sockets.localhost, 8080)
HTTP.serve(ROUTER, Sockets.localhost, 8080)


end