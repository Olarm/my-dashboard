

function create_options(input_data, id)
    name = input_data["name"]
    if name[end-2:end] == "_id"
        name = name[1:end-3]
    end
    list_id = id*"list"
    input_string = """
        <label for='$id'>$name</label>
        <input type="text" list="$list_id" id="$id" name="$name" placeholder="type here..." />
        <datalist id="$list_id">
    """
    for (index, option_data) in enumerate(input_data["options"])
        option_id = "$(name)_$(index)"
        option_name = option_data
        input_string *= """
            <option value="$option_name"></option>
        """
    end
    input_string *= "</datalist>"

    return input_string
end

function create_radio(input_data, input_id)
    name = input_data["name"]
    input_string = "<div class='radio-group'>"
    for (index, option_data) in enumerate(input_data["options"])
        option_id = "$(name)_$(index)"
        option_name = option_data["name"]
        checked = index == 1 ? "checked" : ""
        input_string *= """
        <div>
        <label for='$option_id'>$option_name</label>
        <input
            type='radio'
            name='$input_name'
            id='$option_id' 
        """ * checked * "</div>"
    end
    input_string *= "</div>"
    return input_string
end

function create_generic_input(input_data, input_type, id; float=false)
    name = input_data["name"]
    input_string = """
    <label for='$id'>$name</label>
    <input 
        type='$input_type'
        id='$id'
        name='$name'
    """
    if float
        input_string *= "step='any'"
    end
    input_string *= (input_data["is_nullable"] == "NO" && input_data["data_type"] != "boolean") ? "required" : ""
    input_string *= " />"
    return input_string
end

function create_generic_input(input_data, form_id)
    input_id = form_id * input_data["name"]
    data_type = input_data["data_type"]
    if data_type == "options"
        return create_options(input_data, input_id)
    elseif data_type == "radio"
        return create_radio(input_data, input_id)
    elseif data_type in ["text", "character varying"]
        return create_generic_input(input_data, "text", input_id)
    elseif data_type == "integer"
        return create_generic_input(input_data, "number", input_id)
    elseif data_type in ["number", "numeric", "double precision"]
        return create_generic_input(input_data, "number", input_id, float=true)
    elseif data_type == "email"
        return create_generic_input(input_data, "email", input_id)
    elseif data_type == "date"
        return create_generic_input(input_data, "date", input_id)
    elseif data_type in ["timestamp", "timestamp with time zone", "datetime"]
        return create_generic_input(input_data, "datetime-local", input_id)
    elseif data_type == "boolean"
        return create_generic_input(input_data, "checkbox", input_id)
    else
        @warn "no matching data type for $data_type"
        return ""
    end
end
