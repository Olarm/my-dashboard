
function initiate_nutrients(conn)
    nutrients = (
        ["kilocalorie", "Energy", "Kcal", nothing],
        ["kilojoule", "Energy (kJ)", "kJ", nothing],
        ["gram", "Water", "Water", nothing],
        ["gram", "Protein", "Protein", nothing],
        ["gram", "Total Fat", "Fat", nothing],
        ["gram", "Carbohydrate", "Carb", nothing],
        ["gram", "Dietary Fiber", "Fiber", nothing],
        ["gram", "Alcohol", "Alcohol", nothing],

        # Fat sub-components (Fatty Acids)
        ["gram", "Saturated Fatty Acids", "Sat Fat", "Total Fat"],
        ["gram", "Trans Fatty Acids", "Trans Fat", "Total Fat"],
        ["gram", "Monounsaturated Fatty Acids", "Mono Fat", "Total Fat"],
        ["gram", "Polyunsaturated Fatty Acids", "Poly Fat", "Total Fat"],
        ["gram", "Omega-3 Fatty Acids", "Omega-3", "Polyunsaturated Fatty Acids"],
        ["gram", "Omega-6 Fatty Acids", "Omega-6", "Polyunsaturated Fatty Acids"],
        ["milligram", "Cholesterol", "Cholesterol", nothing],

        # Specific Saturated Fatty Acids (Matvaretabellen tracks these individually)
        ["gram", "C12:0 (Lauric Acid)", "C12:0", "Saturated Fatty Acids"],
        ["gram", "C14:0 (Myristic Acid)", "C14:0", "Saturated Fatty Acids"],
        ["gram", "C16:0 (Palmitic Acid)", "C16:0", "Saturated Fatty Acids"],
        ["gram", "C18:0 (Stearic Acid)", "C18:0", "Saturated Fatty Acids"],

        # Specific Monounsaturated Fatty Acids (Matvaretabellen tracks these)
        ["gram", "C16:1 sum (Palmitoleic Acid)", "C16:1 sum", "Monounsaturated Fatty Acids"],
        ["gram", "C18:1 sum (Oleic Acid)", "C18:1 sum", "Monounsaturated Fatty Acids"],

        # Specific Polyunsaturated Fatty Acids (Matvaretabellen tracks these)
        ["gram", "C18:2n-6 (Linoleic Acid)", "C18:2n-6", "Polyunsaturated Fatty Acids"],
        ["gram", "C18:3n-3 (Alpha-Linolenic Acid)", "C18:3n-3", "Polyunsaturated Fatty Acids"],
        ["gram", "C20:3n-3 (Eicosatrienoic Acid)", "C20:3n-3", "Polyunsaturated Fatty Acids"],
        ["gram", "C20:3n-6 (DGLA)", "C20:3n-6", "Polyunsaturated Fatty Acids"],
        ["gram", "C20:4n-3 (Eicosatetraenoic Acid)", "C20:4n-3", "Polyunsaturated Fatty Acids"],
        ["gram", "C20:4n-6 (Arachidonic Acid)", "C20:4n-6", "Polyunsaturated Fatty Acids"],
        ["gram", "C20:5n-3 (EPA)", "C20:5n-3", "Omega-3 Fatty Acids"],
        ["gram", "C22:5n-3 (DPA)", "C22:5n-3", "Omega-3 Fatty Acids"],
        ["gram", "C22:6n-3 (DHA)", "C22:6n-3", "Omega-3 Fatty Acids"],

        # Carbohydrate sub-components
        ["gram", "Starch", "Starch", "Carbohydrate"],
        ["gram", "Total Sugar", "Sugar", "Carbohydrate"],
        ["gram", "Added Sugar", "Added Sugar", "Total Sugar"],
        ["gram", "Free Sugar", "Free Sugar", "Total Sugar"],

        # Vitamins (Fat-soluble)
        ["microgram", "Vitamin A (RAE)", "Vit A (RAE)", nothing],
        ["microgram", "Vitamin A (RE)", "Vit A (RE)", "Vitamin A (RAE)"],
        ["microgram", "Retinol", "Retinol", "Vitamin A (RE)"],
        ["microgram", "Beta-carotene", "Beta-carotene", "Vitamin A (RE)"],
        ["microgram", "Vitamin D", "Vit D", nothing],
        ["milligram", "Vitamin E (Alpha-Tocopherol)", "Vit E", nothing],

        # Vitamins (Water-soluble)
        ["milligram", "Vitamin C (Ascorbic Acid)", "Vit C", nothing],
        ["milligram", "Thiamin (B1)", "Vit B1", nothing],
        ["milligram", "Riboflavin (B2)", "Vit B2", nothing],
        ["milligram", "Niacin (B3)", "Niacin", nothing],
        ["milligram", "Niacin Equivalents", "Niacin Equiv.", "Niacin (B3)"],
        ["milligram", "Vitamin B6 (Pyridoxine)", "Vit B6", nothing],
        ["microgram", "Folate (B9)", "Folate", nothing],
        ["microgram", "Vitamin B12 (Cobalamin)", "Vit B12", nothing],
        ["microgram", "Biotin (B7)", "Biotin", nothing],
        ["milligram", "Pantothenic Acid (B5)", "Pantothenic Acid", nothing],

        # Minerals & Trace Elements
        ["milligram", "Calcium", "Calcium", nothing],
        ["milligram", "Phosphorus", "Phosphorus", nothing],
        ["milligram", "K (Potassium)", "K", nothing],
        ["milligram", "Na (Sodium)", "Na", nothing],
        ["gram", "Salt (NaCl)", "Salt", "Na (Sodium)"],
        ["milligram", "Magnesium", "Magnesium", nothing],
        ["milligram", "Iron", "Iron", nothing],
        ["milligram", "Zinc", "Zinc", nothing],
        ["milligram", "Copper", "Copper", nothing],
        ["microgram", "Selenium", "Selenium", nothing],
        ["microgram", "Iodine", "Iodine", nothing],
    )
    for n in nutrients
        if n[4] == nothing
            q = """
                INSERT INTO nutrients (unit_id, name, short_name)
                VALUES (
                    (SELECT id FROM units WHERE name = \$1),
                    \$2, \$3
                )
                ON CONFLICT DO NOTHING
            """
            execute(conn, q, n[1:3])
        else
            q = """
                INSERT INTO nutrients (unit_id, name, short_name, parent_nutrient_id)
                VALUES (
                    (SELECT id FROM units WHERE name = \$1),
                    \$2, \$3,
                    (SELECT id FROM nutrients WHERE name = \$4)
                )
                ON CONFLICT DO NOTHING
            """
            execute(conn, q, n)
        end
    end
end

function create_nutrient_table(conn)
    q = """
        CREATE TABLE IF NOT EXISTS nutrients (
            id SERIAL PRIMARY KEY,
            unit_id INT NOT NULL REFERENCES units(id),
            name TEXT UNIQUE NOT NULL,
            short_name TEXT UNIQUE NOT NULL,
            parent_nutrient_id INT REFERENCES nutrients(id)
        )
    """
    execute(conn, q)
    initiate_nutrients(conn)
end

function create_food_categories_table(conn)
    q = """
        CREATE TABLE IF NOT EXISTS food_categories (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL UNIQUE
        );
    """
    execute(conn, q)

    q = """
        INSERT INTO food_categories (name) VALUES
        ('Milk and dairy products'),
        ('Eggs'),
        ('Fats and oils'),
        ('Fish and seafood'),
        ('Meat and meat products'),
        ('Cereals and cereal products'),
        ('Vegetables and vegetable products'),
        ('Potatoes'),
        ('Fruits and berries'),
        ('Nuts and seeds'),
        ('Sugar and confectionery'),
        ('Beverages'),
        ('Other foods'),
        ('Composite dishes'),
        ('Baby food'),
        ('Mushrooms'),
        ('Spices and condiments'),
        ('Herbs'),
        ('Fast food')
        ON CONFLICT (name) DO NOTHING;
    """
    execute(conn, q)
end

function create_foods_table(conn)
    q = """
        DO \$\$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'food_processing_level') THEN
                CREATE TYPE food_processing_level AS ENUM ('unprocessed', 'processed', 'ultraprocessed');
            END IF;
        END
        \$\$
    """
    execute(conn, q)
    q = """
        DO \$\$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'food_database') THEN
                CREATE TYPE food_database AS ENUM ('custom', 'sfcd', 'mattilsynet', 'usda');
            END IF;
        END
        \$\$
    """
    execute(conn, q)
    q = """
        DO \$\$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'preparation') THEN
                CREATE TYPE preparation AS ENUM (
                    'raw', 
                    'boiled', 
                    'steamed', 
                    'cooked', 
                    'fried', 
                    'air-fried', 
                    'grilled'
                );
            END IF;
        END
        \$\$
    """
    execute(conn, q)
    q = """
        CREATE TABLE IF NOT EXISTS foods (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            description TEXT,
            processing food_processing_level NOT NULL,
            food_database food_database NOT NULL,
            preparation preparation NOT NULL DEFAULT 'raw'
        );
    """
    execute(conn, q)
end

function create_food_nutrients_table(conn)
    q = """
        CREATE TABLE IF NOT EXISTS food_nutrients (
            food_id INT NOT NULL REFERENCES foods(id),
            nutrient_id INT NOT NULL REFERENCES nutrients(id),
            amount NUMERIC NOT NULL, -- Amount of the nutrient per standard serving (e.g., per 100g)
            PRIMARY KEY (food_id, nutrient_id)
        );
    """
    execute(conn, q)
end

function create_food_composition_table(conn)
    q = """
        CREATE TABLE IF NOT EXISTS food_compositions (
            composite_food_id INT NOT NULL REFERENCES foods(id) ON DELETE CASCADE,
            component_food_id INT NOT NULL REFERENCES foods(id) ON DELETE CASCADE,
            quantity NUMERIC NOT NULL,
            unit_id INT NOT NULL REFERENCES units(id),
            PRIMARY KEY (composite_food_id, component_food_id), -- A composite food can only contain a specific component once
            CONSTRAINT chk_not_self_referencing CHECK (composite_food_id != component_food_id) -- A food cannot be a component of itself
        );
    """
end

function create_consumption_table(conn)
    q = """
        CREATE TABLE IF NOT EXISTS food_consumption (
            id SERIAL PRIMARY KEY,
            food_id INT NOT NULL REFERENCES foods(id),
            quantity NUMERIC NOT NULL, -- Quantity of the food consumed (e.g., in grams)
            unit_id INT NOT NULL REFERENCES units(id), -- Unit for the quantity (e.g., grams, ml)
            consumption_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
    """
end

function create_food_tables()
    conn = Db.get_conn()
    create_nutrient_table(conn)
    create_food_categories_table(conn)
    create_foods_table(conn)
    create_food_nutrients_table(conn)
    create_food_composition_table(conn)
    create_consumption_table(conn)
    close(conn)
end