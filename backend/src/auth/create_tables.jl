

function create_requests_table(conn)
    q = """
        CREATE TABLE IF NOT EXISTS auth_request_log (
            id SERIAL PRIMARY KEY,
            timestamp timestamp with time zone NOT NULL default (now() at time zone 'utc'),
            http_method TEXT NOT NULL,
            request_url_path TEXT NOT NULL,
            query_parameters TEXT,
            http_protocol_version TEXT NOT NULL,
            user_agent TEXT,
            content_type TEXT,
            content_length TEXT,
            accept_header TEXT,
            user_id INT REFERENCES users(id)
        )
    """
    execute(conn, q)
end



function create_auth_tables()
    conn = Db.get_conn()
    create_requests_table(conn)
    close(conn)
end