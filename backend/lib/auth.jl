module Auth

using HTTP, JSON3, LibPQ, URIs, Dates
import JSONWebTokens

using ..App
using ..Templates: wrap

import ..Db
import ..Users

include("auth/create_tables.jl")

export
    authenticate,
    login_page,
    verify_jwt_token



function generate_jwt(name::String, sub::String)
    payload = Dict(
        "sub" => sub,
        "name" => name, 
        "iat" => time()
    )
    encoding = JSONWebTokens.HS256(App.SECRET_KEY)
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
            encoding = JSONWebTokens.HS256(App.SECRET_KEY)
            payload = JSONWebTokens.decode(encoding, token)
            if time() > (get(payload, "iat", 0) + cookie_time)
                return (ok=false, user=nothing)
            else
                return Users.get_user(payload)
            end
        catch e
            @error e
            return (ok=false, user=nothing)
        end
    end
    return (ok=false, user=nothing)
end


function log_request(req::HTTP.Request, auth)
    function truncate_string(s, max_len::Int)
        if length(s) > max_len
            return first(s, max_len - 3) * "..." # -3 for "..."
        else
            return s
        end
    end

    params = Vector{Any}(undef, 0)
    push!(params, 
        truncate_string(req.method, 256),
        truncate_string(req.target, 256),
        truncate_string(HTTP.URI(req.target).query, 256),
        truncate_string(string(req.version.major, ".", req.version.minor), 256),
        truncate_string(HTTP.header(req, "User-Agent", ""), 256),
        truncate_string(HTTP.header(req, "Content-Type", ""), 256),
        truncate_string(HTTP.header(req, "Content-Length", ""), 256),
        truncate_string(HTTP.header(req, "Accept", ""), 256)
    )

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
    if auth.ok
        push!(params, auth.user.id)
        q = """
            INSERT INTO auth_request_log (
                http_method,
                request_url_path,
                query_parameters,
                http_protocol_version,
                user_agent,
                content_type,
                content_length,
                accept_header,
                user_id
            )
            VALUES (\$1,\$2,\$3,\$4,\$5,\$6,\$7,\$8,\$9)
        """
    end
    conn = Db.get_conn()
    execute(conn, q, params)
    close(conn)
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

function authenticate_user(user::Users.User, password::String)
    stored_hash = user.password_hash
    user_id = user.id

    try
        if Argon2Wrapper.verify_password(password, stored_hash)
            @info "User '$username' authenticated successfully. User ID: $user_id"
            return user_id
        else
            @warn "Authentication failed: Invalid password for user '$username'."
            return nothing
        end
    catch e # Catch any actual, unexpected errors from Argon2Wrapper.verify_password
        @error "Severe Argon2 verification error for user '$username': $(e)"
        return nothing
    end
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



end