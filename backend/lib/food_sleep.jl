module FoodSleepAnalysis
using Main.Db
using DataFrames, PlotlyBase


function food_sleep()
    food = Db.get_per_day()
    sleep = Db.get_sleep()
    df = innerjoin(food, sleep, on=:date)
    return df
end



end