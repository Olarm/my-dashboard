module Auth

using HTTP, JSON3, LibPQ, URIs, Dates
import JSONWebTokens

using ..App
using ..Templates: wrap

export
    authenticate,
    login_page,
    verify_jwt_token


const SECRET_KEY = "your_secret_key"  # Keep this secret

function generate_jwt(name::String, sub::String)
    payload = Dict(
        "sub" => sub,
        "name" => name, 
        "iat" => time()
    )
    encoding = JSONWebTokens.HS256(SECRET_KEY)
    token = JSONWebTokens.encode(encoding, payload)
    return token
end


function verify_jwt_token(req::HTTP.Request)
    cookie_header = HTTP.header(req, "Cookie")
    cookie_time = 3600 * 24 * 100 # 100 days

    if occursin("token=", cookie_header)
        token = split(cookie_header, "token=")[2]
        token = split(token, ";")[1]  # Remove any additional cookie attributes
        @info "Parsing token"
        try
            encoding = JSONWebTokens.HS256(SECRET_KEY)
            payload = JSONWebTokens.decode(encoding, token)
            if time() > (get(payload, "iat", 0) + cookie_time)
                @info "Token ok"
                return (ok=false, payload=nothing)
            else
                @info "Token outdated"
                return (ok=true, payload=payload)
            end
        catch e
            @error e
            return (ok=false, payload=nothing)
        end
    end
    @info "No token in request"
    return (ok=false, payload=nothing)
end


function login_page(req::HTTP.Request)
    html_path = joinpath(App.STATIC_DIR, "auth/login.html")
    wrap_return = wrap(html_path)
    if wrap_return.ok
        html_content = wrap_return.html
        return HTTP.Response(200, Dict("Content-Type" => "text/html"), html_content)
    end
    return HTTP.Response(501)
end

function authenticate(req::HTTP.Request)
    data = JSON3.read(String(req.body))
    name = get(data, "name", "")
    password = get(data, "password", "")
    redirect_url = "/dashboard"

    if name == "admin" && password == "secret"
        user_id = 1
        token = generate_jwt(name, "$user_id")
        set_cookie = "token=$token; HttpOnly; Secure; Path=/; SameSite=Lax"
        if App.config["environment"] == "local"
            set_cookie = "token=$token; HttpOnly; Path=/; SameSite=Lax"
        end

        content = [
            "Location" => "/forms", 
            "Set-Cookie" => set_cookie
            #"Set-Cookie" => "token=$token; HttpOnly; Secure; Path=/; SameSite=Lax"
        ]
        return HTTP.Response(302, content)
    else
        return HTTP.Response(401, JSON3.write(Dict("error" => "Invalid credentials")))
    end
end


end