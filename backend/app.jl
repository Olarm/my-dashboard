module App
using HTTP, JSON3, StructTypes, LibPQ, Sockets, Tables

include("lib/Db.jl")
include("lib/food.jl")

#using Main.SleepAnalysis
using .Db
using .Food
#using Main.StatisticAnalysis



function parse_auth(req)
    @info req
    return true
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

function get_activity(req)
    df = Db.get_activity()
    data = Dict("name" => "Julia", "language" => "Julia", "dates" => df.date, "steps" => df.steps)
    headers = Dict(
        "Access-Control-Allow-Origin" => "*",         # Allow requests from any origin
        "Access-Control-Allow-Methods" => "GET",      # Allow only GET requests
        "Access-Control-Allow-Headers" => "Content-Type", # Allow the Content-Type header
        "Content-Type" => "application/json"          # Ensure response is JSON
    )
    HTTP.Response(200, headers, JSON3.write(data))
end

function get_calories(req)
    @info "getting data"
    df = Food.calories_in_out()
    data = Tables.columntable(df)
    headers = Dict(
        "Access-Control-Allow-Origin" => "*",         # Allow requests from any origin
        "Access-Control-Allow-Methods" => "GET",      # Allow only GET requests
        "Access-Control-Allow-Headers" => "Content-Type", # Allow the Content-Type header
        "Content-Type" => "application/json"          # Ensure response is JSON
    )
    HTTP.Response(200, headers, JSON3.write(data))
end

function get_nasalspray(req)
    return HTTP.Response(200, "hello")
end

initialize()

const ROUTER = HTTP.Router()
#HTTP.register!(ROUTER, "GET", "/api/nasalspray", get_nasalspray)
HTTP.register!(ROUTER, "GET", "/activity", get_activity)
HTTP.register!(ROUTER, "GET", "/calories", get_calories)

#HTTP.serve(ROUTER |> auth_middleware, Sockets.localhost, 8080)
HTTP.serve(ROUTER, Sockets.localhost, 8080)
#HTTP.serve(get_activity, "127.0.0.1", 8080)


end