using DataFrames, LibPQ, JSON3, TimeZones

import .Db: get_conn


function get_exercise(id=24)
    conn = get_conn()
    query = """
        SELECT 
            time,
            latitude,
            longitude 
        FROM gpx_track_points 
        WHERE tcx_id = \$1
        ORDER BY time ASC;
    """
    res = execute(conn, query, [id])

    latitudes = Vector{Float64}()
    longitudes = Vector{Float64}()
    lats_lons = Vector{Vector{Float64}}()
    timestamps = Vector{ZonedDateTime}()
    for row in res
        push!(timestamps, row[1])
        push!(lats_lons, [row[2], row[3]])
        #push!(latitudes, row[2])
        #push!(longitudes, row[3])
    end

    result_json = JSON3.write(Dict(
        "latLons" => lats_lons,
        "timestamps" => timestamps
    ))
    
    return result_json
end