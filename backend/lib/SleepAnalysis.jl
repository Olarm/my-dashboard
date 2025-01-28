module SleepAnalysis
export plot_sleep, combine_data, sleep_classes
using Main.Db
using DataFrames, PlotlyBase, Statistics

function correlations()
    food = Db.get_per_day()
    disallowmissing!(food)
    sleep = Db.get_sleep()
    disallowmissing!(sleep)
    df = innerjoin(food, sleep, on=:date)
    select!(df, Not([:date, :polar_user, :id, :device_id, :sleep_start_time, :sleep_end_time]))
    dropmissing!(df)
    #return df
    cors = [[cor(a, b) for a in eachcol(df)] for b in eachcol(df)]
    return cors
end


function combine_data()
    df_sleep = get_sleep()
    disallowmissing!(df_sleep)
    df_sleep_data = get_sleep_data()
    disallowmissing!(df_sleep_data)

    df = innerjoin(df_sleep, df_sleep_data, on = :date)

    return df
end

function sleep_means()
    df_sleep = get_sleep()
    rem = mean(df.rem_sleep)
    deep = mean(df.deep_sleep)
    light = mean(df.light_sleep)
end


function sleep_classes()
    df = combine_data()
    sleep_types = df[!, [:date, :rem_sleep, :deep_sleep, :light_sleep]]
    return stack(sleep_types, [:rem_sleep, :deep_sleep, :light_sleep], variable_name="sleep_class", value_name="seconds")
end


function plot_sleep()
    df = combine_data()
    p = scatter(
        x=df.date,
        y=df.rem_sleep,
        mode="lines",
        name="Trace 2",
        line=attr(color="blue")
    )
    return p
end



end