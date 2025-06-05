module App

using 
    HTTP, 
    JSON3, 
    StructTypes, 
    LibPQ, 
    Sockets, 
    Tables, 
    TOML

export 
    STATIC_DIR,
    get_dashboard,
    ROUTER

const STATIC_DIR = joinpath(@__DIR__, "frontend")

function get_config()
    open("config.toml", "r") do io
        return TOML.parse(io)
    end
end
config = get_config()

include("lib/template.jl")
include("lib/Db.jl")
include("lib/units.jl")
include("lib/nasalspray.jl")
include("lib/nutrition.jl")

#using Main.SleepAnalysis
using .Db
using .Nutrition
#using Main.StatisticAnalysis

include("lib/users.jl")

Units.create_unit_table()
NasalSprays.create_tables()


function get_headers()
    return Dict(
        "Access-Control-Allow-Origin" => "*",         # Allow requests from any origin
        "Access-Control-Allow-Methods" => "GET",      # Allow only GET requests
        "Access-Control-Allow-Headers" => "Content-Type", # Allow the Content-Type header
        "Content-Type" => "application/json"          # Ensure response is JSON
    )
end

function JSON_middleware(handler)
    return function(req::HTTP.Request)
        if isempty(req.body)
            ret = handler(req)
        else
            req.body = JSON3.read(req.body, Animal)
            ret = handler(req)
        end
        
        if ret isa HTTP.Response
            return ret
        else
            return HTTP.Response(200, CORS_RES_HEADERS, ret === nothing ? "" : JSON3.write(ret))
        end
    end
end

function auth_middleware(handler)
    allowed = (
        "/login", 
        "/authenticate", 
        "/static/style.css",
        "/static/form.css",
        "/static/fonts/RobotoMono-Regular.woff",
        "/static/fonts/RobotoMono-Regular.woff2"
    )

    @info "auth middleware"
    return function(req)
        auth = Auth.verify_jwt_token(req)
        Auth.log_request(req, auth)
        if req.target in allowed
            return handler(req)
        end
        if !auth.ok
            return HTTP.Response(401, "unauthorized")
        else
            user_ret = Users.get_user(auth.payload)
            if !user_ret.ok
                @error "Couldnt get User for user with payload: $(auth.payload))"
                return HTTP.Response(401, "unauthorized, could not get user")
            end
            req.context[:user] = user_ret.user
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

    HTTP.Response(200, get_headers(), data)
end

function get_trips(req)
    data = get_exercises()

    HTTP.Response(200, get_headers(), JSON3.write(data))
end

function get_tcx_list(req)
    data = Db.get_exercises_tcx()
    HTTP.Response(200, get_headers(), JSON3.write(data))
end

function get_dashboard(req)
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
    df = Nutrition.calories_in_out()
    data = Tables.columntable(df)
    HTTP.Response(200, get_headers(), JSON3.write(data))
end

function get_nasalspray(req)
    return HTTP.Response(200, "hello")
end

function test_form_submit(req)
    @info "Test form submit"
    return HTTP.Response(200, "success!")
end

function get_mime_type(file_path::String)
    ext = splitext(file_path)[end]
    mime_types = Dict(
        ".css" => "text/css",
        ".html" => "text/html",
        ".js" => "application/javascript",
        ".png" => "image/png",
        ".jpg" => "image/jpeg",
        ".svg" => "image/svg+xml",
        ".woff" => "font/woff",
        ".woff2" => "font/woff2"
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
        @error "File not found: $(file_path)"
        return HTTP.Response(404, "File not found.")
    end
end

function my_middleware(handler)
    return function(req)
        return handler(req)
    end
end

include("lib/auth.jl")
import .Auth

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
HTTP.register!(ROUTER, "POST", "/test/form/submit", test_form_submit)

# Auth
HTTP.register!(ROUTER, "GET", "/login", Auth.login_page)
HTTP.register!(ROUTER, "POST", "/authenticate", Auth.authenticate)

include("lib/sleep.jl")
include("lib/medicine.jl")
include("lib/weight.jl")
include("lib/bss.jl")
include("lib/forms.jl")
Medicines.create_medicine_tables()
Weights.create_weight_tables()
Bsss.create_bss_tables()
Nutrition.create_nutrition_tables()


host = Sockets.localhost
if config["environment"] == "local"
    host = "0.0.0.0"
end
port = get(config, "port", 8080)
server = HTTP.serve!(ROUTER |> auth_middleware, host, port)

end