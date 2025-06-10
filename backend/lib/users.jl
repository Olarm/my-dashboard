module Users
export 
    create_users_table

using LibPQ
import ..Db
import ..Argon2


struct User
    id::Int
    username::String
    first_name::String
    last_name::String
    email::String
    sex::String
    admin::Bool
    password_hash::String
end

struct UserInput
    username::String
    first_name::String
    last_name::String
    email::String
    sex::String
    password_hash::String
end

function create_user(data::AbstractDict)::Union{User, Nothing}
    username = get(data, "username", nothing)
    if isnothing(username) || isempty(string(username))
        @error "Missing or empty username."
        return nothing
    end
    username_str = string(username)

    first_name = get(data, "first_name", nothing)
    first_name_str = isnothing(first_name) ? nothing : string(first_name)

    last_name = get(data, "last_name", nothing)
    last_name_str = isnothing(last_name) ? nothing : string(last_name)

    email = get(data, "email", nothing)
    if isnothing(email) || isempty(string(email))
        @error "Missing or empty email."
        return nothing
    end
    email_str = string(email)
    if !occursin(r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$", email_str)
        @error "Invalid email format for: $(email_str)."
        return nothing
    end

    sex_input = get(data, "sex", nothing)
    if isnothing(sex_input) || isempty(string(sex_input)) || length(string(sex_input)) != 1
        @error "Missing, empty, or invalid 'sex'. Must be a single character."
        return nothing
    end
    sex_char = first(string(sex_input))

    password = get(data, "password", nothing)
    if password == nothing
        @error "Missing or empty password"
        return false
    end
    password_hash = Argon2.hash_password(password)

    return User(
        username_str,
        first_name_str,
        last_name_str,
        email_str,
        sex_char,
        password_hash
    )
end

function create_users_table(conn)
    q = """
        CREATE TABLE if not exists users (
            id SERIAL PRIMARY KEY,
            username TEXT NOT NULL UNIQUE,
            first_name TEXT,
            last_name TEXT,
            email VARCHAR(255) NOT NULL UNIQUE,
            sex VARCHAR(1) NOT NULL,
            admin BOOLEAN DEFAULT FALSE NOT NULL,
            CONSTRAINT email_format_check CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\$'),
            password_hash TEXT NOT NULL
        )
    """
    execute(conn, q)
end

function get_user(jwt_payload)
    @info jwt_payload
    id_str = get(jwt_payload, "sub", "")
    if id_str == ""
        @error "Got empty id_str"
        return (ok=false, user=nothing)
    end

    id = tryparse(Int, id_str)
    if id == nothing
        @error "Cant parse id_str to Int"
        return (ok=false, user=nothing)
    end

    conn = Db.get_conn()
    q = """SELECT 
            id, 
            username, 
            first_name, 
            last_name, 
            email, 
            sex, 
            admin 
        FROM users WHERE id = \$1
    """
    result = execute(conn, q, [id])

    if isempty(result)
        @error "Couldnt find user with $id in db"
        return (ok=false, user=nothing)
    end
    
    user_row = nothing
    for row in result
        user_row = [i for i in row]
    end

    return (ok=true, user=User(user_row...))
end

end