module Food

using DataFrames

include("Db.jl")

import Main.Db


function calories_per_day()
    df = Db.get_food()
    total_calories = sum(df.calories ./100 .* df.amount)
    dt = df.dateeaten[end] - df.dateeaten[1]
    total_days = convert(Float64, dt.value) / (1000*60*60*24)
    return total_calories / total_days
end


function calories_in_out()
    food = Db.get_per_day()
    food[!, "calories eaten"] = food.calories
    activity = Db.get_activity()
    activity[!, "calories burned"] = activity.kilocalories
    df = innerjoin(food, activity, on=:date)
    select!(df, Not([:calories, :kilocalories]))
    return df
end

end