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

function get_exercises()

    conn = get_conn()
    query = """
        SELECT json_build_object(
        'tcx_ids', jsonb_agg(tcx_id),
        'latLons', jsonb_agg(coordinate_group),
        'timestamps', jsonb_agg(timestamp_group)
    ) AS result
    FROM (
        SELECT 
            tcx_id,
            jsonb_agg(jsonb_build_array(latitude, longitude)) AS coordinate_group,
            jsonb_agg(time) AS timestamp_group
        FROM gpx_track_points
        GROUP BY tcx_id
        ) subquery
    """
    res = execute(conn, query)

    json_result = JSON3.read(res[1, :result])
    
    return json_result
end