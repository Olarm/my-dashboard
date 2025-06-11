
function create_table_rows(df::DataFrame)
    html_string = ""
    for row in eachrow(df)
        html_string *= "<tr>"
        for item in row
            html_string *= "<td>$item</td>"
        end
        html_string *= "</tr>"
    end
    return html_string
end

function create_table(df::DataFrame, table_id)
    headers = join(["<th>$name</th>" for name in names(df)])
    html_string = """
    <table id=$table_id>
        <thead>
            <tr>$headers</tr>
        </thead>
        <tbody>
    """
    html_string *= create_table_rows(df)
    html_string *= "</tbody></table>"
    return html_string
end