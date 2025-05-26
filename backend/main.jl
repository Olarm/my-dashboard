using Dates
using Sockets
using HTTP

const LOG_DIR = "/var/log/my_dashboard"
const LOG_FILE = joinpath(LOG_DIR, "service.log")
const PID_DIR = "/var/run/my_dashboard"
const PID_FILE = joinpath(PID_DIR, "service.pid")

function ensure_directory(path::String, mode=0o755)
    !isdir(path) && mkpath(path, mode=mode)
end

function log_message(level::Symbol, msg::String)
    timestamp = Dates.format(Dates.now(), "yyyy-mm-dd HH:MM:SS")
    log_entry = "[$timestamp] [$(uppercase(string(level)))] $msg\n"
    try
        open(LOG_FILE, "a") do io
            write(io, log_entry)
        end
    catch e
        # Fallback to stderr if file logging fails
        @warn "Failed to write to log file $LOG_FILE: $e. Message: $msg"
        Base.printstyled(stderr, log_entry, color=:red)
    end
end

function run_service()
    log_message(:info, "Loading app.jl and starting HTTP server...")
    try
        include("app.jl")
        log_message(:info, "HTTP server started on $(App.host):$(App.port)")
    catch e
        log_message(:error, "Failed to load or start app.jl: $e")
        isfile(PID_FILE) && read(PID_FILE, String) == string(current_pid) && rm(PID_FILE)
        exit(1)
    end

    # This prevents immediate exit when systemd sends SIGTERM
    try
        Base.exit_on_signal(Base.SIGTERM, false)
        log_message(:info, "SIGTERM handler configured. Waiting for termination signal...")
    catch e
        log_message(:error, "Failed to configure SIGTERM handler: $e")
        # Depending on criticality, you might exit here or proceed with less graceful handling
    end

    # Use a Channel to block the main task until a signal is caught
    shutdown_channel = Channel{Bool}(1)
    try
        take!(shutdown_channel) # This task will block indefinitely
    catch e
        if isa(e, InterruptException)
            log_message(:info, "SIGTERM received (InterruptException). Attempting graceful shutdown.")
            if isdefined(App, :server) && isa(App.server, Sockets.TCPServer)
                log_message(:info, "Closing HTTP server via App.server...")
                close(App.server)
                log_message(:info, "HTTP server closed.")
            else
                log_message(:warn, "Could not find `App.server` or it's not a TCPServer for graceful closure.")
            end
        else
            log_message(:error, "Caught unexpected error during shutdown wait: $e")
        end
    finally
        log_message(:info, "Service shutting down.")
        if isfile(PID_FILE) && read(PID_FILE, String) == string(current_pid)
            try
                rm(PID_FILE)
                log_message(:info, "Removed PID file: $PID_FILE")
            catch e
                log_message(:warn, "Failed to remove PID file $PID_FILE: $e")
            end
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    using Pkg
    Pkg.activate(".")
    Pkg.instantiate()

    run_service()
end