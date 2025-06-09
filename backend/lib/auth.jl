module Auth

using HTTP, JSON3, LibPQ, URIs, Dates
import JSONWebTokens

using ..App
using ..Templates: wrap

import ..Db

include("auth/create_tables.jl")

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
        try
            encoding = JSONWebTokens.HS256(SECRET_KEY)
            payload = JSONWebTokens.decode(encoding, token)
            if time() > (get(payload, "iat", 0) + cookie_time)
                return (ok=false, payload=nothing)
            else
                return (ok=true, payload=payload)
            end
        catch e
            @error e
            return (ok=false, payload=nothing)
        end
    end
    return (ok=false, payload=nothing)
end

function create_request_log_table(conn)
    q = """
        CREATE TABLE IF NOT EXISTS auth_request_log (
            id SERIAL PRIMARY KEY,
            http_method TEXT NOT NULL,
            request_url_path TEXT NOT NULL,
            query_parameters TEXT NOT NULL,
            http_protocol_version TEXT NOT NULL,
            user_agent TEXT,
            content_type TEXT,
            content_length TEXT,
            accept_header TEXT
        )
    """
    execute(conn, q)
end

function log_request(req::HTTP.Request, auth)
    function truncate_string(s::String, max_len::Int)
        if length(s) > max_len
            return first(s, max_len - 3) * "..." # -3 for "..."
        else
            return s
        end
    end

    params = [
        req.method
        req.target
        HTTP.URI(req.target).query
        string(req.version.major, ".", req.version.minor)
        HTTP.header(req, "User-Agent", "")
        HTTP.header(req, "Content-Type", "")
        HTTP.header(req, "Content-Length", "")
        HTTP.header(req, "Accept", "")
    ]
    params = [truncate_string(i, 256) for i in params]

    q = """
        INSERT INTO auth_request_log (
            http_method,
            request_url_path,
            query_parameters,
            http_protocol_version,
            user_agent,
            content_type,
            content_length,
            accept_header
        )
        VALUES (\$1,\$2,\$3,\$4,\$5,\$6,\$7,\$8)
    """
    execute(conn, q, params)
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
    redirect_url = "/forms"

    if name == "admin" && password == "secret"
        user_id = 1
        max_age_seconds = 3600 * 24 * 100 # 100 days
        token = generate_jwt(name, "$user_id")
        set_cookie_header = "token=$token; HttpOnly; Path=/; SameSite=Lax; Max-Age=$(max_age_seconds)"
        if App.config["environment"] != "local"
            set_cookie_header = "$(set_cookie_header); Secure"
        end

        content = [
            "Location" => redirect_url, 
            "Set-Cookie" => set_cookie_header
        ]
        return HTTP.Response(302, content)
    else
        return HTTP.Response(401, JSON3.write(Dict("error" => "Invalid credentials")))
    end
end

function create_auth_tables()
    conn = Db.get_conn()
    create_request_log_table(conn)
    close(conn)
end


end