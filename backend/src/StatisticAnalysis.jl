module StatisticAnalysis
using Statistics

export correlations


function correlations()
    food = Db.get_per_day()
    sleep = Db.get_sleep()
    df = innerjoin(food, sleep, on=:date)
    
end

end