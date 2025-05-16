module Medicines

using 
    HTTP, 
    JSON3, 
    Dates, 
    LibPQ,
    DataFrames
using ..Templates
import ..App
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
    

    HTTP.Response(200, App.get_headers(), JSON3.write(form))
end

HTTP.register!(App.ROUTER, "GET", "/medicine/administration-log-form", get_administration_log_form)
end