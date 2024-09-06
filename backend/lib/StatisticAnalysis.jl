module StatisticAnalysis
using Statistics, DataFrames

export gen_numbers, calc_mean, calc_macro_food_parts, get_macros_long_df

function gen_numbers(N::Int)
    return rand(N)
end

function calc_mean(x::Vector{Float64})
    return round(sum(x) / length(x); digits=4)
end

function calc_macro_food_parts(df)
    fat = mean(df.fat)
    carbs = mean(df.carbs)
    proteins = mean(df.proteins)
    total = fat + carbs + proteins
    data = Dict(
        "fat" => fat,
        "carbs" => carbs,
        "proteins" => proteins,
        "total" => total
    )
    data["pct_fat"] = fat / total
    data["pct_carbs"] = carbs / total
    data["pct_proteins"] = proteins / total
    return data
end

function get_macros_long_df(df)
    return stack(df[!, [:date, :carbs, :fat, :proteins]], Not([:date]), variable_name="nutrient", value_name="amount")
end
end