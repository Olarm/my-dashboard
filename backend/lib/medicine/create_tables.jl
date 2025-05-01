

function create_ingredients_tables()
    conn = Db.get_conn()
    q = """
        CREATE TABLE IF NOT EXISTS medicine_ingredients (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT
        );
    """
    execute(conn, q)

end

function create_measurement_units_table()
    conn = Db.get_conn()
    q = """
        CREATE TABLE IF NOT EXISTS medicine_measurement_unit (
            id SERIAL PRIMARY KEY,
            unit_code VARCHAR(10) NOT NULL UNIQUE, -- Short code for the unit (e.g., 'mg', 'ml')
            description TEXT NOT NULL -- Full description or friendly name of the unit
        );
    """
    execute(conn, q)

    q = """
        INSERT INTO medicine_measurement_unit (unit_code, description) VALUES
        ('mg', 'Milligrams'),
        ('g', 'Grams'),
        ('kg', 'Kilograms'),
        ('ml', 'Milliliters'),
        ('l', 'Liters'),
        ('IU', 'International Units'),
        ('mcg', 'Micrograms'),
        ('ng', 'Nanograms'),
        ('mEq', 'Milliequivalents'),
        ('mmol', 'Millimoles')
        ON CONFLICT (unit_code) DO NOTHING;
    """
    execute(conn, q)
end

function create_medicine_ingredients_table()
    conn = Db.get_conn()
    q = """
        CREATE TABLE IF NOT EXISTS medicine_medicine_ingredient (
            medicine_id INT NOT NULL,
            ingredient_id INT NOT NULL,
            quantity DECIMAL(10, 2), -- Quantity of the ingredient in the medicine
            unit_id INT NOT NULL,    -- Foreign key referencing the measurement unit
            PRIMARY KEY (medicine_id, ingredient_id),
            FOREIGN KEY (medicine_id) REFERENCES medicine_medicine(id),
            FOREIGN KEY (ingredient_id) REFERENCES medicine_ingredients(id),
            FOREIGN KEY (unit_id) REFERENCES medicine_measurement_unit(id)
        );
    """
    execute(conn, q)
end


function create_medicine_administration_method_table()
    conn = Db.get_conn()
    q = """
        CREATE TABLE IF NOT EXISTS medicine_administration_methods (
            id SERIAL PRIMARY KEY,
            method TEXT NOT NULL,
            form TEXT NOT NULL,
            short_form VARCHAR(3),
            description TEXT NOT NULL,
            UNIQUE (method, form) 
        )
    """
    execute(conn, q)

    q = """
        INSERT INTO medicine_administration_methods (method, form, short_form, description) VALUES
        ('Oral', 'Tablet', NULL, 'Swallowed whole with water.'),
        ('Oral', 'Capsule', NULL, 'Swallowed whole with water.'),
        ('Oral', 'Chewable Tablet', NULL, 'Chewed before swallowing.'),
        ('Oral', 'Effervescent Tablet', NULL, 'Dissolved in water before drinking.'),
        ('Oral', 'Liquid', NULL, 'Syrup, suspension, or solution.'),
        ('Oral', 'Sublingual', NULL, 'Placed under the tongue to dissolve.'),
        ('Oral', 'Buccal', NULL, 'Placed between the cheek and gum to dissolve.'),
        ('Injection', 'Intravenous', 'IV', 'Directly into a vein.'),
        ('Injection', 'Intramuscular', 'IM', 'Into a muscle.'),
        ('Injection', 'Subcutaneous', 'SC', 'Under the skin.'),
        ('Injection', 'Intradermal', 'ID', 'Into the skin.'),
        ('Injection', 'Intraosseous', 'IO', 'Into the bone marrow.'),
        ('Topical', 'Cream, Ointment, and Gel', NULL, 'Applied directly to the skin.'),
        ('Topical', 'Patch', NULL, 'Adhesive patch that releases medication through the skin.'),
        ('Inhalation', 'Inhaler', NULL, 'Used for delivering medication to the lungs.'),
        ('Inhalation', 'Nebulizer', NULL, 'Converts liquid medication into a mist for inhalation.'),
        ('Nasal', 'Spray', NULL, 'Delivered through the nose.'),
        ('Nasal', 'Drop', NULL, 'Applied into the nostril.'),
        ('Rectal', 'Suppository', NULL, 'Inserted into the rectum.'),
        ('Rectal', 'Enema', NULL, 'Liquid medication administered into the rectum.'),
        ('Vaginal', 'Cream, Gel, and Suppository', NULL, 'Inserted into the vagina.'),
        ('Ocular', 'Eye Drop', NULL, 'Applied directly to the eye.'),
        ('Ocular', 'Ointment', NULL, 'Applied to the eye or eyelid.'),
        ('Otic', 'Ear Drop', NULL, 'Applied into the ear canal.'),
        ('Transdermal', 'Patch', NULL, 'Delivers medication through the skin over an extended period.')
        ON CONFLICT (method, form) DO NOTHING;
    """
    execute(conn, q)
end


function create_medicines_table()
    conn = Db.get_conn()
    q = """
        CREATE TABLE IF NOT EXISTS medicine_medicine (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL,
            administration_method_id INT NOT NULL,
            FOREIGN KEY (administration_method_id) REFERENCES medicine_administration_methods(id)
        )
    """
    execute(conn, q)
    Db.insert_foreign_meta("medicine_medicine", ["name"])
end


function create_medicine_administration_log_table()
    conn = Db.get_conn()
    q = """
        CREATE TABLE IF NOT EXISTS medicine_administration_log (
            id SERIAL PRIMARY KEY,
            medicine_id INT NOT NULL,
            user_id INT NOT NULL,
            dosage DECIMAL(10, 2),
            administration_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            notes TEXT,
            FOREIGN KEY (medicine_id) REFERENCES medicine_medicine(id),
            FOREIGN KEY (user_id) REFERENCES users(id)
        );
    """
    execute(conn, q)
end