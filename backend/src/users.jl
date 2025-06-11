module Users
export 
    create_users_table

using LibPQ
import ..Db
import ..Argon2


struct UserInput
    username::String
    first_name::Union{String, Nothing}
    last_name::Union{String, Nothing}
    email::String
    sex::String
    password_hash::String
end

struct User
    id::Int
    username::String
    first_name::Union{String, Nothing}
    last_name::Union{String, Nothing}
    email::String
    sex::String
    admin::Bool

    function User(user_input::UserInput, id::Int)
        User(
            id,
            user_input.username,
            user_input.first_name,
            user_input.last_name,
            user_input.email,
            user_input.sex,
            false
        )
    end
end



"""
    insert_user_into_db(user::User)::Union{Int, Nothing}

Inserts a UserInput struct into the 'users' PostgreSQL table.
Returns the 'id' of the newly inserted user on success, or nothing on failure.
"""
function insert_user_into_db(user_input::UserInput)::Union{User, Nothing}
    try
        conn = Db.get_conn()

        q = """
            INSERT INTO users (username, first_name, last_name, email, sex, admin, password_hash)
            VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7)
            RETURNING id;
        """

        result = LibPQ.execute(conn, sql, [
            user_input.username,
            user_input.first_name,
            user_input.last_name,
            user_input.email,
            string(user_input.sex), # Convert Char to String for the database
            user_input.admin,
            user_input.password_hash
        ])

        inserted_id = LibPQ.getrows(result, (:id,))[1]
        @info "Successfully inserted user '$(user_input.username)' with ID: $inserted_id."
        new_user = User(user_input, inserted_id)
        return new_user

    catch e
        @error "Failed to insert user into database: $(e)"
        return nothing
    finally
        if !isnothing(conn) && LibPQ.isopen(conn)
            close(conn)
        end
    end
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

    user_data = User(
        username_str,
        first_name_str,
        last_name_str,
        email_str,
        sex_char,
        password_hash
    )

    return insert_user_into_db(user_data)
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