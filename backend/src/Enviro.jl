module Enviro

export get_df, get_temperature

using SQLite, DataFrames


function get_df()
    db = SQLite.DB("2024_04_18-2024_05_20.db")
    query = "SELECT * FROM enviro ORDER BY timestamp;"
    return DBInterface.execute(db, query) |> DataFrame
end


function get_temperature()
    df = get_df()
    temperature = df.temperature
    return temperature[1:100]
end
end