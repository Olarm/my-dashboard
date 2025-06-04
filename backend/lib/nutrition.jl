module Nutrition

using 
    DataFrames, 
    Statistics, 
    LibPQ

import ..Db

include("nutrition/create_tables.jl")


function calories_in_out()
    food = disallowmissing(Db.get_food_per_day())
    food[!, "calories in"] = food.calories
    activity = dropmissing(Db.get_activity())
    activity[!, "calories out"] = activity.kilocalories
    sleep = Db.get_sleep()
    dropmissing!(sleep)
    recharge = dropmissing(Db.get_recharge())
    eat_sleep_score = Db.get_eat_sleep_score()
    df = innerjoin(food, activity, on=:date)
    df = innerjoin(df, sleep, on=:date)
    df = innerjoin(df, recharge, on=:date)
    df = innerjoin(df, eat_sleep_score, on=:date)
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