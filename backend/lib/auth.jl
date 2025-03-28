module Auth

using HTTP, JSON3, LibPQ, URIs, Dates
import JSONWebTokens

using ..App: STATIC_DIR, get_dashboard
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

    if occursin("token=", cookie_header)
        token = split(cookie_header, "token=")[2]
        token = split(token, ";")[1]  # Remove any additional cookie attributes
        try
            encoding = JSONWebTokens.HS256(SECRET_KEY)
            payload = JSONWebTokens.decode(encoding, token)
            return (ok=true, payload=payload)
        catch e
            return (ok=false, payload=nothing)
        end
    end
    return (ok=false, payload=nothing)
end


function login_page(req::HTTP.Request)
    html_path = joinpath(STATIC_DIR, "auth/login.html")
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
        token = generate_jwt(name, "1")
        return HTTP.Response(302, ["Location" => "/dashboard", "Set-Cookie" => "token=$token; HttpOnly; Secure; Path=/; SameSite=Lax"])
    else
        return HTTP.Response(401, JSON3.write(Dict("error" => "Invalid credentials")))
    end
end


end