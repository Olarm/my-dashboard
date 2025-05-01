module Events

using Dates, LibPQ

import ..Db



function create_meta_data_table()
    conn = Db.get_conn()
    q = """
        CREATE TABLE IF NOT EXISTS meta_data (
            id SERIAL PRIMARY KEY,
            name text not null,
            friendly_names boolean not null default false,
            description text not null
        )
    """
    execute(conn, q)
end


function create_categorical_data_table()
    conn = Db.get_conn()
    q = """
        CREATE TABLE IF NOT EXISTS categorical_data (
            id SERIAL PRIMARY KEY,
            value INTEGER NOT NULL,
            friendly_name TEXT NOT NULL
        )
    """
    execute(conn, q)
end


function create_timestamp_category_table()
    # e.g nasalspray, bss
    conn = Db.get_conn()
    q = """
        CREATE TABLE IF NOT EXISTS timestamp_integer (
            timestamp timestamp with time zone not null,
            FOREIGN KEY (meta_data_id) REFERENCES meta_data(id) 
                NOT NULL
                ON DELETE CASCADE
                ON UPDATE CASCADE,
            FOREIGN KEY (categorical_data_id) REFERENCES categorical_data(id) 
                NOT NULL
                ON DELETE CASCADE
                ON UPDATE CASCADE
        )
    """
    execute(conn, q)
end


function create_timestamp_double_table()
    conn = Db.get_conn()
    q = """
        CREATE TABLE IF NOT EXISTS timestamp_double (
            timestamp timestamp with time zone not null,
            value double not null,
            FOREIGN KEY (meta_data_id) REFERENCES meta_data(id)
                ON DELETE CASCADE
                ON UPDATE CASCADE
        )
    """
end


function create_event_tables()
    create_meta_data_table()
    create_categorical_data_table()
    create_timestamp_category_table()
    create_timestamp_double_table()

end


end