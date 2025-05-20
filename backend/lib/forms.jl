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
            c.table_name = \$1
        ORDER BY c.ordinal_position;
    """
    params = [table_name]
    return execute(conn, q, params)
end

function get_foreign_options(table_name)

    function foreign_options_query(conn, data, table_name)
        descriptors = data.descriptors[1][2:end-1]
        id_col = data.identifier[1]
        q = """SELECT $id_col, $descriptors FROM $table_name;"""
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
            row_dict["options"] = foreigns.data.name
        end
        push!(data, row_dict)
    end
    return data
end

function serve_forms(req)
    html_path = joinpath(App.STATIC_DIR, "forms2.html")
    wrap_return = Templates.wrap(html_path)
    if wrap_return.ok
        html_content = wrap_return.html
        form_html = """
          <h1>Dropdown with searchable text</h1>
          <form id="myForm">
            <label for="myHouse">Choose your magical house:</label>
            <input type="text" list="magicHouses" id="myHouse" name="myHouse" placeholder="type here..." />
            <datalist id="magicHouses">
                <option label="label">Gryfindor</option>
                <option value="2">Hufflepuff</option>
                <option value="3">Slytherin</option>
                <option value="4">Ravenclaw</option>
                <option value="5">Horned Serpent</option>
                <option value="6">Thunderbird</option>
                <option value="7">Pukwudgie</option>
                <option value="8">Wampus</option>
            </datalist>
            <input name="Submit"  type="submit" value="Update" />
          </form>
        """
        #html_content = Templates.insert_content(html_content, form_html, "test-form")

        test_table_data = create_table_form("test")
        test_form = Templates.create_form(test_table_data, "test-form", "/test/form/submit")
        html_content = Templates.insert_content(html_content,test_form, "test-form")
        
        sleep_table_data = create_table_form("sleep_data")
        sleep_form = Templates.create_form(sleep_table_data, "sleep-data-form", "/sleep/create")
        html_content = Templates.insert_content(html_content, sleep_form, "sleep-form")
        return HTTP.Response(200, Dict("Content-Type" => "text/html"), html_content)
    end
    return HTTP.Response(501)
end

HTTP.register!(App.ROUTER, "GET", "/forms", serve_forms)

end