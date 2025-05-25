#!/usr/bin/env julia

using Pkg

# Activate the project environment
path = "/opt/my_dashboard/backend"
Pkg.activate(path)

include(path*"/app.jl")