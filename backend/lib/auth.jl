module Auth

using HTTP, JSON3, LibPQ

using ..App: STATIC_DIR
using ..Templates: wrap

export
    authenticate,
    login_page


function login_page(req::HTTP.Request)
    html_path = joinpath(STATIC_DIR, "auth/login.html")
    wrap_return = wrap(html_path)
    if wrap_return.ok
        html_content = wrap_return.html
        return HTTP.Response(200, Dict("Content-Type" => "text/html"), html_content)
    end
    return HTTP.Response(501)
end

function authenticate()
    return HTTP.Response(200)
end


end