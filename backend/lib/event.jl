module Events

using 
    HTTP,
    Dates, 
    LibPQ,
    JSON3,
    DataFrames,
    Dates,
    TimeZones

import ..App
import ..Db
import ..Templates

function initiate_event_meta(conn)
    q = """
        INSERT INTO event_meta_data 
            (name, short_name, unit, unit_short, description, event_table_name)
        VALUES
            (
                'Bristol stool scale',
                'bss',
                'Integers in [1,7]',
                '[1,7]',
                'Stool quality classification method',
                'event_timestamp_category'
            ),
            (
                'Weight',
                'weight',
                'Kilograms',
                'kg',
                'Weight in kilograms',
                'event_timestamp_double'
            )
        ON CONFLICT DO NOTHING;
    """
    execute(conn, q)
end

function get_event_meta(id::Int)
    conn = Db.get_conn()
    q = "SELECT * from event_meta_data WHERE id = \$1"
    df = execute(conn, q, [id]) |> DataFrame
    if size(df)[1] != 1
        return (ok=false, data=nothing)
    end
    return (ok=true, data=df)
end

function get_event_meta(id_name::String)
    id_str, name = split(id_name, " ")
    id = parse(Int, id_str)
    return get_event_meta(id)
end

function create_meta_data_table()
    conn = Db.get_conn()
    q = """
        CREATE TABLE IF NOT EXISTS event_meta_data (
            id SERIAL PRIMARY KEY,
            name text not null unique,
            short_name text not null unique,
            unit text not null,
            unit_short text not null,
            description text,
            event_table_name text not null
        )
    """
    execute(conn, q)
    Db.insert_foreign_meta("event_meta_data", ["name", "unit"])
    initiate_event_meta(conn)
end


function create_categorical_data_table()
    conn = Db.get_conn()
    q = """
        CREATE TABLE IF NOT EXISTS event_categorical_data (
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
        CREATE TABLE IF NOT EXISTS event_timestamp_category (
            timestamp timestamp with time zone not null,
            FOREIGN KEY (meta_data_id) REFERENCES event_meta_data(id) 
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

struct TimestampDoubleEvent
    timestamp::ZonedDateTime
    value::Float64
    meta_data_id::Int
end

function create_timestamp_double_table()
    conn = Db.get_conn()
    q = """
        CREATE TABLE IF NOT EXISTS event_timestamp_double (
            timestamp timestamp with time zone not null,
            meta_data_id integer not null,
            value double precision not null,
            FOREIGN KEY (meta_data_id) REFERENCES event_meta_data(id)
                ON DELETE CASCADE
                ON UPDATE CASCADE,
            UNIQUE (timestamp, meta_data_id)
        )
    """
    execute(conn, q)
end

function create_event_tables()
    create_meta_data_table()
    #create_categorical_data_table()
    #create_timestamp_category_table()
    create_timestamp_double_table()
end

function create_timestamp_double_event(req::HTTP.Request)
    @info "creating timestamp double event"
    body = JSON3.read(String(req.body))
    event_meta_data = get_event_meta(body["meta_data"])
    @info event_meta_data
    @info body
    HTTP.Response(200)
end

HTTP.register!(App.ROUTER, "POST", "/event/timestamp_double/create", create_timestamp_double_event)

end