module Medicines

using 
    HTTP, 
    JSON3, 
    Dates, 
    LibPQ,
    DataFrames
using ..Templates
import ..FeedbackLoop
import ..Db
import ..Forms

include("medicine/create_tables.jl")


function create_medicine_tables()
    create_measurement_units_table()
    create_medicine_administration_method_table()
    create_medicines_table()
    create_ingredients_tables()
    create_medicine_ingredients_table()
    create_medicine_administration_log_table()
end

function get_administration_log_form(req::HTTP.Request)
    form = Forms.create_table_form("medicine_administration_log")
    HTTP.Response(200, FeedbackLoop.get_headers(), JSON3.write(form))
end

function get_medicine_administration_log(n, user_id)
    conn = Db.get_conn()
    q = """
        SELECT 
            a.administration_time,
            m.name,
            a.dosage
        FROM medicine_administration_log a
        LEFT JOIN medicine_medicine m
            ON m.id = a.medicine_id
        WHERE a.user_id = \$1
        ORDER BY a.administration_time DESC
        LIMIT \$2;
    """
    df = execute(conn, q, [user_id, n]) |> DataFrame
    close(conn)
    return df
end

function create_medicine_log(req::HTTP.Request)
    @info "creating medicine log"
    body = JSON3.read(String(req.body))
    @info body
    HTTP.Response(200)
end

HTTP.register!(FeedbackLoop.ROUTER, "GET", "/medicine/administration-log-form", get_administration_log_form)
HTTP.register!(FeedbackLoop.ROUTER, "POST", "/medicine/log/create", create_medicine_log)
end