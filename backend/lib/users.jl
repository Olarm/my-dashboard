module Users
export 
    create_users_table

using LibPQ

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

end