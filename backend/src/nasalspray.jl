module NasalSprays

using HTTP, JSON3, Dates, LibPQ
using ..Templates
import ..FeedbackLoop
import ..Db



function create_nasalspray_types()
    conn = Db.get_conn()
    q = """
        CREATE TABLE if not exists nasalspray_types (
            id SERIAL PRIMARY KEY,
            active_ingredient text not null,
            description text not null unique,
            name text not null unique
            )
    """
    execute(conn, q)
end


function create_nasalspray()
    conn = Db.get_conn()
    q = """
        CREATE TABLE if not exists nasalspray (
            pk SERIAL PRIMARY KEY,
            timestamp timestamp with time zone not null,
            usage varchar(1) not null,
            FOREIGN KEY (nasalspray_type_id) REFERENCES nasalspray_types(id)
                ON DELETE CASCADE
                ON UPDATE CASCADE
        )
    """
    execute(conn, q)
end

function create_tables()
    create_nasalspray_types()
    create_nasalspray()
end

end