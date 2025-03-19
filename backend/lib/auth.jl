module Auth

using HTTP, JSON3, LibPQ

using ..App: STATIC_DIR

export
    authenticate,
    login_page

function login_page(req::HTTP.Request)
    path = joinpath(STATIC_DIR, "login.html")
    html_content = read(path, String)

    return HTTP.Response(200, Dict("Content-Type" => "text/html"), html_content)
end

function authenticate()
    return HTTP.Response(200)
end


end