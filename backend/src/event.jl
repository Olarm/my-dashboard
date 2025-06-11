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
    close(conn)
end

function get_event_meta(id::Int)
    conn = Db.get_conn()
    q = "SELECT * from event_meta_data WHERE id = \$1"
    df = execute(conn, q, [id]) |> DataFrame
    close(conn)
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
    close(conn)
end

function initiate_bss_category(conn)
    q = """
        INSERT INTO event_categorical_data 
            (value, friendly_name)
        VALUES
            (1, '1'),
            (2, '2'),
            (3, '3'),
            (4, '4'),
            (5, '5'),
            (6, '6'),
            (7, '7')
    """
    execute(conn, q)
    close(conn)
end

function create_categorical_data_table()
    conn = Db.get_conn()
    q = """
        CREATE TABLE IF NOT EXISTS event_categorical_data (
            id SERIAL PRIMARY KEY,
            value INTEGER NOT NULL,
            friendly_name TEXT NOT NULL
        );
    """
    execute(conn, q)
    initiate_bss_category(conn)
    close(conn)
end

function create_timestamp_category_table()
    # e.g bss
    conn = Db.get_conn()
    q = """
        CREATE TABLE IF NOT EXISTS event_timestamp_category (
            timestamp timestamp with time zone not null,
            categorical_data_id integer not null REFERENCES event_categorical_data(id) ON DELETE RESTRICT,
            meta_data_id integer not null REFERENCES event_meta_data(id) ON DELETE RESTRICT,
        )
    """
    execute(conn, q)
    close(conn)
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
    close(conn)
end

function create_event_tables()
    create_meta_data_table()
    create_categorical_data_table()
    create_timestamp_category_table()
    create_timestamp_double_table()
end

function create_timestamp_double_event(meta_id, body)
    conn = Db.get_conn()
    q = """
        INSERT INTO event_timestamp_double (
            timestamp, meta_data_id, value
        )
        VALUES (
            \$1, \$2, \$3
        )
    """
    execute(conn, q, [body["timestamp"], meta_id, body["value"]])
    close(conn)
end

function post_timestamp_double_event(req::HTTP.Request)
    @info "creating timestamp double event"
    body = JSON3.read(String(req.body))
    event_meta_data = get_event_meta(body["meta_data"])
    if event_meta_data.data.event_table_name != "event_timestamp_double"
        HTTP.Response(400)
    end
    @info event_meta_data
    @info body
    create_timestamp_double_event(event_meta_data.data.id[1], body)
    HTTP.Response(200)
end

function create_timestamp_category_event(meta_id, body)
    conn = Db.get_conn()
    q = """
        INSERT INTO event_timestamp_double (
            timestamp, meta_data_id, value
        )
        VALUES (
            \$1, \$2, \$3
        )
    """
    execute(conn, q, [body["timestamp"], meta_id, body["value"]])
    close(conn)
end

function post_timestamp_category_event(req::HTTP.Request)
    @info "creating timestamp category event"
    body = JSON3.read(String(req.body))
    event_meta_data = get_event_meta(body["meta_data"])
    if event_meta_data.data.event_table_name != "event_timestamp_double"
        HTTP.Response(400)
    end
    @info event_meta_data
    @info body
    create_timestamp_double_event(event_meta_data.data.id[1], body)
    HTTP.Response(200)
end

HTTP.register!(App.ROUTER, "POST", "/event/timestamp_double/create", post_timestamp_double_event)

end