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
    return JSONWebTokens.encode(encoding, payload)
end

function verify_jwt_token(req::HTTP.Request)
    auth_header = get(HTTP.header(req, "Authorization"), "")

    if startswith(auth_header, "Bearer ")
        token = split(auth_header, " ")[2]
        try
            payload = JWTs.decode(token, SECRET_KEY, :HS256)
            return payload  # Token is valid
        catch
            return nothing  # Invalid token
        end
    end
    return nothing  # No token provided
end

function login_page(req::HTTP.Request)
    @info "login page"
    html_path = joinpath(STATIC_DIR, "auth/login.html")
    wrap_return = wrap(html_path)
    if wrap_return.ok
        html_content = wrap_return.html
        return HTTP.Response(200, Dict("Content-Type" => "text/html"), html_content)
    end
    return HTTP.Response(501)
end

function authenticate(req::HTTP.Request)
    @info "authentication"
    data = JSON3.read(String(req.body))
    name = get(data, "name", "")
    password = get(data, "password", "")
    redirect_url = "/dashboard"

    if name == "admin" && password == "secret"
        token = generate_jwt(name, "1")
        @info "Login successful for user: $(name)"
        return HTTP.Response(200, JSON3.write(Dict("token" => token, "redirect" => redirect_url)))
    else
        @info "Login failed for user: $(name)"
        return HTTP.Response(401, JSON3.write(Dict("error" => "Invalid credentials")))
    end

    #uri = URIs.URI(req.target)
    #req.target = ""
    #query_params = URIs.queryparams(uri)
    #@info query_params
    #return HTTP.Response(200)
    return get_dashboard(req)
end


end