module Templates

export wrap

include("template/forms.jl")

using ..App: STATIC_DIR


function render_template(base_html::String, content_html::String, section_name="content")
    pattern_str = "{%\\s*begin $(section_name)\\s*%}(.*?){%\\s*end $(section_name)\\s*%}"
    content_match = match(Regex(pattern_str, "s"), content_html)
    
    if content_match !== nothing
        replacement_content = content_match.captures[1]  # Extract content inside tags
        
        rendered_html = replace(base_html, Regex(pattern_str, "s") => replacement_content)
        
        return rendered_html
    else
        return base_html
    end
end

function insert_content(base_html::String, content_html::String, section_name)
    pattern_str = "{%\\s* $(section_name) \\s*%}"
    content_match = match(Regex(pattern_str, "s"), base_html)
    if content_match !== nothing
        rendered_html = replace(base_html, Regex(pattern_str, "s") => content_html)
        return rendered_html
    else
        return base_html
    end
end

function match_extend(path, content_html)
    extends = match(r"{%\s*extends\s*'([^']+)'", content_html)
    if extends !== nothing
        if length(extends.captures) != 1
            @error "Multiple extends in $(path)"
            return (ok=false, html="")
        end
        path = joinpath(STATIC_DIR, extends.captures[1])
        base_html = read(path, String)
        html = render_template(base_html, content_html)
        return match_extend(path, html)
    else
        return (ok=true, html=content_html)
    end
end

function create_form(form_data, form_id, rel_url)
    form = """<form id='$form_id' data-action='processForm' data-url='$rel_url'>"""
    for input_data in form_data
        if input_data["primary_key"] == true
            continue
        end
        form *= create_generic_input(input_data, form_id)
    end
    #form *= "<input name='Submit'  type='submit' value='Update' />"
    form *= "<br><button type='submit'>Submit</button>"
    form *= "</form>"
    return form
end

function wrap(path)
    html_content = read(path, String)
    match_extend(path, html_content)
end

end