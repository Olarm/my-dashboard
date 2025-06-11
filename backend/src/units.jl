module Units

using 
    LibPQ,
    DataFrames

import ..Db

struct Unit
end


function initiate_units(conn)
    units = (
        ["calorie",     "calories", "cal", "energy", "imperial", ""],
        ["kilocalorie", "kilocalories", "kcal", "energy", "imperial", "kilo"],
        ["joule",       "joules", "J", "energy", "metric", ""],
        ["kilojoule",   "kilojoules", "kJ", "energy", "metric", "kilo"],
        ["second",      "seconds", "s", "time", "metric", ""],
        ["metre",       "metres", "m", "length", "metric", ""],
        ["kilometre",   "kilometres", "km", "length", "metric", "kilo"],
        ["microgram", "micrograms", "μg", "mass", "metric", "micro"],
        ["milligram", "milligrams", "mg", "mass", "metric", "milli"],
        ["gram", "grams", "g", "mass", "metric", ""],
        ["kilogram", "kilograms", "kg", "mass", "metric", "kilo"]
    )
    for unit in units
        q = """
            INSERT INTO units(name, name_plural, code, quantity, system, magnitude)
            VALUES(\$1, \$2, \$3, \$4, \$5, \$6)
            ON CONFLICT DO NOTHING;
        """
        execute(conn, q, unit)
    end
    close(conn)
end

function create_unit_table()
    conn = Db.get_conn()
    q = """
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'measurement_system') THEN
            CREATE TYPE measurement_system AS ENUM ('metric', 'imperial');
        END IF;
    END
    \$\$
    """
    execute(conn, q)

    q = """
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'unit_magnitude') THEN
            CREATE TYPE unit_magnitude AS ENUM (
                'nano',
                'micro', 
                'milli',
                'centi',
                'deci',
                '',
                'deca',
                'hecto',
                'kilo',
                'mega',
                'giga'
            );
        END IF;
    END
    \$\$
    """
    execute(conn, q)

    q = """
        CREATE TABLE IF NOT EXISTS units (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            name_plural TEXT NOT NULL UNIQUE,
            code TEXT NOT NULL UNIQUE,
            quantity TEXT NOT NULL,
            system measurement_system NOT NULL,
            magnitude unit_magnitude NOT NULL
        );
    """
    execute(conn, q)
    initiate_units(conn)
    close(conn)
end



end