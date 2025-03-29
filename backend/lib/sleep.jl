module Sleep

using HTTP, JSON3, Dates
import ..App


struct SleepData
    date::Date
    location::String    
    room::String
    twin_bed::Bool
    sleep_solo::Bool
    mouth_tape::Bool
    nose_magnet::Bool
end


function create_sleep_data(req::HTTP.Request)
    data = try
        JSON3.read(req.body)
    catch e
        if e isa MethodError
            return HTTP.Response(400, "bad input")
        else
            return HTTP.Response(500)
        end
    end

    @info data
end

HTTP.register!(App.ROUTER, "POST", "/sleep/create")

end