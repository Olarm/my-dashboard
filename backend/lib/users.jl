module Users
export 
    create_users_table

using LibPQ
import ..Db


struct User
    id::Int
    username::String
    first_name::String
    last_name::String
    email::String
    sex::String
    admin::Bool
end

function create_users_table(conn)
    q = """
        CREATE TABLE if not exists users (
            id SERIAL PRIMARY KEY,
            username TEXT,
            first_name TEXT,
            last_name TEXT,
            email VARCHAR(255) NOT NULL,
            sex VARCHAR(1) NOT NULL,
            admin BOOLEAN DEFAULT FALSE NOT NULL,
            CONSTRAINT email_format_check CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\$'),
            CONSTRAINT unique_username UNIQUE(username),
            CONSTRAINT unique_email UNIQUE(email)
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