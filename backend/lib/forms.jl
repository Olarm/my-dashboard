module Forms

using 
    HTTP, 
    JSON3, 
    Dates, 
    LibPQ,
    DataFrames,
    Tables
import ..Templates
import ..App
import ..Db
import ..Weights
import ..Sleep
import ..Medicines
import ..Bsss
import ..Users


function table_info_query(table_name)
    conn = Db.get_conn()
    q = """
        SELECT
            c.column_name AS name,
            c.data_type,
            c.column_default AS default,
            c.is_nullable,
            CASE
                WHEN pk.column_name IS NOT NULL THEN true
                ELSE false
            END AS primary_key,
            CASE
                WHEN fk.column_name IS NOT NULL THEN true
                ELSE false
            END AS foreign_key,
            fk_ref.foreign_table_name AS references_table
        FROM
            INFORMATION_SCHEMA.COLUMNS c
        LEFT JOIN (
            SELECT
                kcu.column_name,
                kcu.table_name
            FROM
                INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
            JOIN
                INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
            ON
                tc.constraint_name = kcu.constraint_name
                AND tc.table_name = kcu.table_name
            WHERE
                tc.constraint_type = 'PRIMARY KEY'
        ) pk
        ON
            c.column_name = pk.column_name AND c.table_name = pk.table_name
        LEFT JOIN (
            SELECT
                kcu.column_name,
                kcu.table_name
            FROM
                INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
            JOIN
                INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
            ON
                tc.constraint_name = kcu.constraint_name
                AND tc.table_name = kcu.table_name
            WHERE
                tc.constraint_type = 'FOREIGN KEY'
        ) fk
        ON
            c.column_name = fk.column_name AND c.table_name = fk.table_name
        LEFT JOIN (
            SELECT
                kcu.column_name,
                kcu.table_name,
                ccu.table_name AS foreign_table_name
            FROM
                INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
            JOIN
                INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
            ON
                tc.constraint_name = kcu.constraint_name
                AND tc.table_name = kcu.table_name
            JOIN
                INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE ccu
            ON
                tc.constraint_name = ccu.constraint_name
            WHERE
                tc.constraint_type = 'FOREIGN KEY'
        ) fk_ref
        ON
            c.column_name = fk_ref.column_name AND c.table_name = fk_ref.table_name
        WHERE
            c.table_name = \$1 AND NOT
            c.column_name like '%timezone'
        ORDER BY c.ordinal_position;
    """
    params = [table_name]
    return execute(conn, q, params)
end

function get_foreign_options(table_name)
    # TODO: Get target table as well and query where id is in it

    function foreign_options_query(conn, data, table_name)
        descriptors = data.descriptors[1][2:end-1]
        id_col = data.identifier[1]
        q = """SELECT $id_col id, $descriptors FROM $table_name;"""
        result = execute(conn, q)
        return DataFrame(result)
    end

    conn = Db.get_conn()
    q = """
        SELECT * FROM table_foreign_meta 
        WHERE table_name = \$1  
    """
    params = [table_name]
    result = execute(conn, q, params)
    data = columntable(result)

    foreign_options = foreign_options_query(conn, data, table_name)
    return (ok=true, data=foreign_options)
end

function create_table_form(table_name; user_id=false)
    result = table_info_query(table_name)
    data = []
    for row in result
        row_dict = Dict{String,Any}()
        if row[1] == "user_id" && user_id == false
            continue
        end
        for (i, col) in enumerate(LibPQ.column_names(result))
            row_dict[col] = row[i]
        end
        if row[6] == true
            @info "ITS A FOREIGN KEY"
            foreigns = get_foreign_options(row[7])
            @info foreigns
            row_dict["data_type"] = "options"
            row_dict["options"] = ["$(r.id) $(r.name)" for r in eachrow(foreigns.data)]
            #"$(foreigns.data.id) $(foreigns.data.name)"
        end
        push!(data, row_dict)
    end
    return data
end

function add_form(html_content, table_name, form_id, relative_url)
    data = create_table_form(table_name)
    form = Templates.create_form(data, form_id, relative_url)
    html_content = Templates.insert_content(html_content, form, form_id)
    return html_content
end

function add_form(html_content, table_name, form_id, relative_url, get_func, user::Users.User)
    data = create_table_form(table_name)
    last_five = get_func(5, user.id)
    form = Templates.create_form_with_table(data, form_id, relative_url, last_five)
    html_content = Templates.insert_content(html_content, form, form_id)
    return html_content
end

function serve_forms(req)
    user = req.context[:user]
    html_path = joinpath(App.STATIC_DIR, "forms2.html")
    wrap_return = Templates.wrap(html_path)
    if wrap_return.ok
        html_content = wrap_return.html
        html_content = add_form(html_content, "medicine_administration_log", "medicine-administration-log-form", "/medicine/log/create", Medicines.get_medicine_administration_log, user)
        html_content = add_form(html_content, "sleep_data", "sleep-data-form", "/sleep/create", Sleep.get_sleep_data, user)
        html_content = add_form(html_content, "weight", "weight-form", "/weight/create", Weights.get_weight, user)
        html_content = add_form(html_content, "bss", "bss-form", "/bss/create", Bsss.get_bss, user)
        return HTTP.Response(200, Dict("Content-Type" => "text/html"), html_content)
    end
    return HTTP.Response(501)
end

HTTP.register!(App.ROUTER, "GET", "/forms", serve_forms)

end