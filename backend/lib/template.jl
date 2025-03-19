module Templates

export wrap

using ..App: STATIC_DIR


function render_template(base_html::String, content_html::String)
    # Regular expression to extract content inside {% begin content %} ... {% end content %}
    content_match = match(r"{%\s*begin content\s*%}(.*?){%\s*end content\s*%}"s, content_html)
    
    if content_match !== nothing
        replacement_content = content_match.captures[1]  # Extract content inside tags
        
        # Replace the {% begin content %} block in base_html with extracted content
        rendered_html = replace(base_html, r"{%\s*begin content\s*%}.*?{%\s*end content\s*%}"s => replacement_content)
        
        return rendered_html
    else
        return base_html  # If no content is found, return original base HTML
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
        return (ok=true, html=html)
    else
        return (ok=true, html=content_html)
    end
end


function wrap(path)
    html_content = read(path, String)
    match_extend(path, html_content)
end

end