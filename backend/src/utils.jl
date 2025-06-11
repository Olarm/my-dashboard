module Utils

function parse_nullable_integer(s::AbstractString)
    if isempty(s)
        return nothing
    else
        try
            return parse(Int, s)
        catch e
            if isa(e, ArgumentError)
                @warn "String \"$s\" is not empty and not a valid integer. Returning `nothing`."
                return nothing
            else
                @error "Failed to parse string \"$s\" as an integer. Error: $(e)"
                return nothing
            end
        end
    end
end

end