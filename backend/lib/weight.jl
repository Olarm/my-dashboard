module Weights

using 
    HTTP, 
    JSON3, 
    Dates,
    TimeZones, 
    LibPQ,
    DataFrames

using ..Templates
import ..App
import ..Db
import ..Forms


function initialize()
    conn = Db.get_conn()
    q = """
        INSERT INTO meta_data (name, short_name, description, unit, unit_short)
        VALUES('Weight', '', '', 'Kilograms', 'kg')
        ON CONFLICT DO NOTHING
    """
    execute(conn, q)
end

end