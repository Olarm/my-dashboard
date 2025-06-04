
function initiate_nutrients(conn)
    nutrients = (
        # --- Macronutrients & Energy ---
        # Category: 'Macronutrients & Energy'
        ["kilocalorie", "Energy", "Kcal", "Energy"],
        ["kilojoule", "Energy (kJ)", "kJ", "Energy"],
        ["gram", "Water", "Water", "Macronutrients"],
        ["gram", "Protein", "Protein", "Macronutrients"],
        ["gram", "Total Fat", "Fat", "Macronutrients"],
        ["gram", "Carbohydrate", "Carb", "Macronutrients"],
        ["gram", "Dietary Fiber", "Fiber", "Macronutrients"],
        ["gram", "Alcohol", "Alcohol", "Macronutrients"],

        # --- Fats & Lipids ---
        # Category: 'Fats & Lipids'
        ["gram", "Saturated Fatty Acids", "Sat Fat", "Total Fat", "Fats & Lipids"],
        ["gram", "Trans Fatty Acids", "Trans Fat", "Total Fat", "Fats & Lipids"],
        ["gram", "Monounsaturated Fatty Acids", "Mono Fat", "Total Fat", "Fats & Lipids"],
        ["gram", "Polyunsaturated Fatty Acids", "Poly Fat", "Total Fat", "Fats & Lipids"],
        ["gram", "Omega-3 Fatty Acids", "Omega-3", "Polyunsaturated Fatty Acids", "Fats & Lipids"],
        ["gram", "Omega-6 Fatty Acids", "Omega-6", "Polyunsaturated Fatty Acids", "Fats & Lipids"],
        ["milligram", "Cholesterol", "Cholesterol", "Fats & Lipids"],

        # Specific Saturated Fatty Acids
        ["gram", "C12:0 (Lauric Acid)", "C12:0", "Saturated Fatty Acids", "Fats & Lipids"],
        ["gram", "C14:0 (Myristic Acid)", "C14:0", "Saturated Fatty Acids", "Fats & Lipids"],
        ["gram", "C16:0 (Palmitic Acid)", "C16:0", "Saturated Fatty Acids", "Fats & Lipids"],
        ["gram", "C18:0 (Stearic Acid)", "C18:0", "Saturated Fatty Acids", "Fats & Lipids"],

        # Specific Monounsaturated Fatty Acids
        ["gram", "C16:1 sum (Palmitoleic Acid)", "C16:1 sum", "Monounsaturated Fatty Acids", "Fats & Lipids"],
        ["gram", "C18:1 sum (Oleic Acid)", "C18:1 sum", "Monounsaturated Fatty Acids", "Fats & Lipids"],

        # Specific Polyunsaturated Fatty Acids
        ["gram", "C18:2n-6 (Linoleic Acid)", "C18:2n-6", "Polyunsaturated Fatty Acids", "Fats & Lipids"],
        ["gram", "C18:3n-3 (Alpha-Linolenic Acid)", "C18:3n-3", "Polyunsaturated Fatty Acids", "Fats & Lipids"],
        ["gram", "C20:3n-3 (Eicosatrienoic Acid)", "C20:3n-3", "Polyunsaturated Fatty Acids", "Fats & Lipids"],
        ["gram", "C20:3n-6 (DGLA)", "C20:3n-6", "Polyunsaturated Fatty Acids", "Fats & Lipids"],
        ["gram", "C20:4n-3 (Eicosatetraenoic Acid)", "C20:4n-3", "Polyunsaturated Fatty Acids", "Fats & Lipids"],
        ["gram", "C20:4n-6 (Arachidonic Acid)", "C20:4n-6", "Polyunsaturated Fatty Acids", "Fats & Lipids"],
        ["gram", "C20:5n-3 (EPA)", "C20:5n-3", "Omega-3 Fatty Acids", "Fats & Lipids"],
        ["gram", "C22:5n-3 (DPA)", "C22:5n-3", "Omega-3 Fatty Acids", "Fats & Lipids"],
        ["gram", "C22:6n-3 (DHA)", "C22:6n-3", "Omega-3 Fatty Acids", "Fats & Lipids"],

        # --- Carbohydrate Sub-components ---
        # Category: 'Carbohydrate Sub-components'
        ["gram", "Starch", "Starch", "Carbohydrate", "Carbohydrate Sub-components"],
        ["gram", "Resistant Starch", "Resist Starch", "Carbohydrate", "Carbohydrate Sub-components"],
        ["gram", "Total Sugar", "Sugar", "Carbohydrate", "Carbohydrate Sub-components"],
        ["gram", "Added Sugar", "Added Sugar", "Total Sugar", "Carbohydrate Sub-components"],
        ["gram", "Free Sugar", "Free Sugar", "Total Sugar", "Carbohydrate Sub-components"],

        # --- Fat-soluble Vitamins ---
        # Category: 'Fat-soluble Vitamins'
        ["microgram", "Vitamin A (RAE)", "Vit A (RAE)", "Fat-soluble Vitamins"],
        ["microgram", "Vitamin A (RE)", "Vit A (RE)", "Vitamin A (RAE)", "Fat-soluble Vitamins"],
        ["microgram", "Retinol", "Retinol", "Vitamin A (RE)", "Fat-soluble Vitamins"],
        ["microgram", "Beta-carotene", "Beta-carotene", "Vitamin A (RE)", "Fat-soluble Vitamins"],
        ["microgram", "Vitamin D", "Vit D", "Fat-soluble Vitamins"],
        ["milligram", "Vitamin E (Alpha-Tocopherol)", "Vit E", "Fat-soluble Vitamins"],
        ["microgram", "Vitamin K", "Vit K", "Fat-soluble Vitamins"],

        # --- Other Carotenoids ---
        # Category: 'Other Carotenoids'
        ["microgram", "Lutein + Zeaxanthin", "Lut + Zea", "Other Carotenoids"],
        ["microgram", "Lycopene", "Lycopene", "Other Carotenoids"],
        ["microgram", "Beta-Cryptoxanthin", "Beta-Cryp", "Other Carotenoids"],
        ["microgram", "Alpha-carotene", "Alpha-car", "Other Carotenoids"],

        # --- Vitamin-like Nutrients ---
        # Category: 'Vitamin-like Nutrients'
        ["milligram", "Choline", "Choline", "Vitamin-like Nutrients"],

        # --- Water-soluble Vitamins ---
        # Category: 'Water-soluble Vitamins'
        ["milligram", "Vitamin C (Ascorbic Acid)", "Vit C", "Water-soluble Vitamins"],
        ["milligram", "Thiamin (B1)", "Vit B1", "Water-soluble Vitamins"],
        ["milligram", "Riboflavin (B2)", "Vit B2", "Water-soluble Vitamins"],
        ["milligram", "Niacin (B3)", "Niacin", "Water-soluble Vitamins"],
        ["milligram", "Niacin Equivalents", "Niacin Equiv.", "Niacin (B3)", "Water-soluble Vitamins"],
        ["milligram", "Vitamin B6 (Pyridoxine)", "Vit B6", "Water-soluble Vitamins"],
        ["microgram", "Folate (B9)", "Folate", "Water-soluble Vitamins"],
        ["microgram", "Vitamin B12 (Cobalamin)", "Vit B12", "Water-soluble Vitamins"],
        ["microgram", "Biotin (B7)", "Biotin", "Water-soluble Vitamins"],
        ["milligram", "Pantothenic Acid (B5)", "Pantothenic Acid", "Water-soluble Vitamins"],

        # --- Minerals ---
        # Category: 'Minerals' (Major Minerals)
        ["milligram", "Calcium", "Calcium", "Minerals"],
        ["milligram", "Phosphorus", "Phosphorus", "Minerals"],
        ["milligram", "K (Potassium)", "K", "Minerals"],
        ["milligram", "Na (Sodium)", "Na", "Minerals"],
        ["gram", "Salt (NaCl)", "Salt", "Na (Sodium)", "Minerals"],
        ["milligram", "Magnesium", "Magnesium", "Minerals"],
        ["milligram", "Chloride", "Cl", "Minerals"],

        # --- Trace Elements ---
        # Category: 'Trace Elements' (Microminerals)
        ["milligram", "Iron", "Iron", "Trace Elements"],
        ["milligram", "Zinc", "Zinc", "Trace Elements"],
        ["milligram", "Copper", "Copper", "Trace Elements"],
        ["microgram", "Selenium", "Selenium", "Trace Elements"],
        ["microgram", "Iodine", "Iodine", "Trace Elements"],
        ["milligram", "Manganese", "Mn", "Trace Elements"],
        ["microgram", "Chromium", "Cr", "Trace Elements"],
        ["microgram", "Molybdenum", "Mo", "Trace Elements"],
        ["microgram", "Boron", "Boron", "Trace Elements"],
        ["milligram", "Fluoride", "Fluoride", "Trace Elements"],

        # --- Amino Acids ---
        # Category: 'Amino Acids'
        ["milligram", "Histidine", "Histidine", "Protein", "Amino Acids"],
        ["milligram", "Isoleucine", "Isoleucine", "Protein", "Amino Acids"],
        ["milligram", "Leucine", "Leucine", "Protein", "Amino Acids"],
        ["milligram", "Lysine", "Lysine", "Protein", "Amino Acids"],
        ["milligram", "Methionine", "Methionine", "Protein", "Amino Acids"],
        ["milligram", "Phenylalanine", "Phenylalanine", "Protein", "Amino Acids"],
        ["milligram", "Threonine", "Threonine", "Protein", "Amino Acids"],
        ["milligram", "Tryptophan", "Tryptophan", "Protein", "Amino Acids"],
        ["milligram", "Valine", "Valine", "Protein", "Amino Acids"],
        ["milligram", "Cystine (Cysteine)", "Cystine", "Protein", "Amino Acids"],
        ["milligram", "Tyrosine", "Tyrosine", "Protein", "Amino Acids"],

        # --- Other Bioactive Compounds ---
        ["milligram", "Caffeine", "Caffeine", "Other Bioactive Compounds"]
    )

    for n in nutrients
        if length(n) == 4
            @info n
            q = """
                INSERT INTO foods_nutrients (unit_id, name, short_name, category_id)
                VALUES (
                    (SELECT id FROM units WHERE name = \$1),
                    \$2, \$3,
                    (SELECT id FROM foods_nutrient_categories WHERE name = \$4)
                )
                ON CONFLICT DO NOTHING
            """
            execute(conn, q, n)
        elseif length(n) == 5
            q = """
                INSERT INTO foods_nutrients (unit_id, name, short_name, parent_nutrient_id, category_id)
                VALUES (
                    (SELECT id FROM units WHERE name = \$1),
                    \$2, \$3,
                    (SELECT id FROM foods_nutrients WHERE name = \$4),
                    (SELECT id FROM foods_nutrient_categories WHERE name = \$5)
                )
                ON CONFLICT DO NOTHING
            """
            execute(conn, q, n)
        else
            @warn "Nutrient $n has wrong number of arguments"
        end
    end
end

function create_nutrient_category_table(conn)
    q = """
        CREATE TABLE IF NOT EXISTS foods_nutrient_categories (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            description TEXT -- Optional: if you want to add more detail to categories later
        );
    """
    execute(conn, q)
    q = """
        INSERT INTO foods_nutrient_categories (name) VALUES
            ('Energy'),
            ('Macronutrients'),
            ('Fats & Lipids'),
            ('Carbohydrate Sub-components'),
            ('Fat-soluble Vitamins'),
            ('Water-soluble Vitamins'),
            ('Vitamin-like Nutrients'), -- For Choline
            ('Other Carotenoids'),      -- For Lutein, Lycopene etc.
            ('Minerals'),               -- Major minerals
            ('Trace Elements'),         -- Minor minerals
            ('Amino Acids'),             -- Protein building blocks
            ('Other Bioactive Compounds')
        ON CONFLICT (name) DO NOTHING;
    """
    execute(conn, q)
end

function create_nutrient_table(conn)
    q = """
        CREATE TABLE IF NOT EXISTS foods_nutrients (
            id SERIAL PRIMARY KEY,
            unit_id INT NOT NULL REFERENCES units(id),
            name TEXT UNIQUE NOT NULL,
            short_name TEXT UNIQUE NOT NULL,
            parent_nutrient_id INT REFERENCES foods_nutrients(id),
            category_id INT REFERENCES foods_nutrient_categories(id) NOT NULL
        )
    """
    execute(conn, q)
    initiate_nutrients(conn)
end

function create_food_databases_table(conn)
    q = """
        CREATE TABLE IF NOT EXISTS foods_source_databases (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            name_short TEXT NOT NULL UNIQUE
        )
    """
    execute(conn, q)
    q = """
        INSERT INTO foods_source_databases (name, name_short)
        VALUES 
            ('Custom', 'Custom'),
            ('Swiss Food Composition Database', 'SFCD'),
            ('United States Department of Agriculture', 'USDA'),
            ('Matvaretabellen', 'Matvaretabellen')
        ON CONFLICT DO NOTHING
    """
    execute(conn, q)
end

function create_food_categories_table(conn)
    q = """
        CREATE TABLE IF NOT EXISTS foods_food_categories (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL UNIQUE
        );
    """
    execute(conn, q)

    q = """
        INSERT INTO foods_food_categories (name) VALUES
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
        CREATE TABLE IF NOT EXISTS foods_foods (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            description TEXT,
            processing food_processing_level NOT NULL,
            source_database_id INT REFERENCES foods_source_databases(id)
        );
    """
    execute(conn, q)
end

function create_food_nutrients_table(conn)
    q = """
        CREATE TABLE IF NOT EXISTS foods_foods_nutrients (
            food_id INT NOT NULL REFERENCES foods_foods(id),
            nutrient_id INT NOT NULL REFERENCES foods_nutrients(id),
            amount NUMERIC NOT NULL, -- Amount of the nutrient per standard serving (e.g., per 100g)
            PRIMARY KEY (food_id, nutrient_id)
        );
    """
    execute(conn, q)
end

function create_food_composition_table(conn)
    q = """
        CREATE TABLE IF NOT EXISTS foods_compositions (
            composite_food_id INT NOT NULL REFERENCES foods_foods(id) ON DELETE CASCADE,
            component_food_id INT NOT NULL REFERENCES foods_foods(id) ON DELETE CASCADE,
            quantity NUMERIC NOT NULL,
            unit_id INT NOT NULL REFERENCES units(id),
            PRIMARY KEY (composite_food_id, component_food_id), -- A composite food can only contain a specific component once
            CONSTRAINT chk_not_self_referencing CHECK (composite_food_id != component_food_id) -- A food cannot be a component of itself
        );
    """
end

function create_consumption_table(conn)
    q = """
        CREATE TABLE IF NOT EXISTS foods_consumed (
            id SERIAL PRIMARY KEY,
            food_id INT NOT NULL REFERENCES foods_foods(id),
            quantity NUMERIC NOT NULL, -- Quantity of the food consumed (e.g., in grams)
            unit_id INT NOT NULL REFERENCES units(id), -- Unit for the quantity (e.g., grams, ml)
            consumption_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
    """
end

function create_food_tables()
    conn = Db.get_conn()
    create_nutrient_category_table(conn)
    create_nutrient_table(conn)
    create_food_databases_table(conn)
    create_food_categories_table(conn)
    create_foods_table(conn)
    create_food_nutrients_table(conn)
    create_food_composition_table(conn)
    create_consumption_table(conn)
    close(conn)
end