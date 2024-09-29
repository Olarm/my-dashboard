module Food

using DataFrames, Statistics


import ..Db


function calories_per_day()
    df = Db.get_food()
    total_calories = sum(df.calories ./100 .* df.amount)
    dt = df.dateeaten[end] - df.dateeaten[1]
    total_days = convert(Float64, dt.value) / (1000*60*60*24)
    return total_calories / total_days
end


function calories_in_out()
    food = disallowmissing(Db.get_per_day())
    food[!, "calories in"] = food.calories
    activity = dropmissing(Db.get_activity())
    activity[!, "calories out"] = activity.kilocalories
    sleep = Db.get_sleep()
    disallowmissing!(sleep)
    df = innerjoin(food, activity, on=:date)
    df = innerjoin(df, sleep, on=:date)
    df = select!(df, Not([
        :calories, 
        :kilocalories, 
        :pk, 
        :inactivity_stamps,
        :device_id,
        :polar_user,
        :id
    ]))
    return df
end

struct CorrMatrix
    cols::Vector{String}
    M::Matrix{Float64}
end

function correlation_matrix()
    df = calories_in_out()
    df = select!(df, Not([
        :date,
        :sleep_start_time,
        :sleep_end_time,
        :sleep_goal,
        :unrecognized_sleep_stage,
        :salt
    ]))
    cols = names(df)
    M = cor(Array{Float64}(Matrix(df)))
    CorrMatrix(cols, M)
end
end