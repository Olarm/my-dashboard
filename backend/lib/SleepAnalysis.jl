module SleepAnalysis
export plot_sleep, combine_data, sleep_classes
using Main.Db
using DataFrames, PlotlyBase


function combine_data()
    df_sleep = get_sleep()
    disallowmissing!(df_sleep)
    df_sleep_data = get_sleep_data()
    disallowmissing!(df_sleep_data)

    df = innerjoin(df_sleep, df_sleep_data, on = :date)

    return df
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