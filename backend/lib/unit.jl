module Units

using 
    LibPQ,
    DataFrames

import ..Db

struct Unit
end


function initiate_units(conn)
    units = (
        ["calorie",     "calories", "cal", "energy"],
        ["kilocalorie", "kilocalories", "kcal", "energy"],
        ["joule",       "joules", "J", "energy"],
        ["kilojoule",   "kilojoules", "kJ", "energy"],
        ["second",      "seconds", "s", "time"],
        ["metre",       "metres", "m", "length"],
        ["kilometre",   "kilometres", "km", "length"],
        ["microgram", "micrograms", "μg", "mass"],
        ["milligram", "milligrams", "mg", "mass"],
        ["gram", "grams", "g", "mass"],
        ["kilogram", "kilograms", "kg", "mass"]
    )
    for unit in units
        q = """
            INSERT INTO units(name, name_plural, code, measures)
            VALUES(\$1, \$2, \$3 \$4)
            ON CONFLICT DO NOTHING;
        """
        execute(conn, q, unit)
    end
    close(conn)
end

function create_unit_table()
    conn = Db.get_conn()
    q = """
        CREATE TABLE IF NOT EXISTS units (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            name_plural TEXT NOT NULL UNIQUE,
            code TEXT NOT NULL UNIQUE
        )
    """
    execute(conn, q)
    initiate_units(conn)
    close(conn)
end



end