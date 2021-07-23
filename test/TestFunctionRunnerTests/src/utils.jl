module Utils

using Base: AbstractCmd

struct CompletedProcess
    stdout::String
    stderr::String
    process::Base.Process
end

"""
    capture(cmd::AbstractCmd) -> process::CompletedProcess

Like `run(cmd)` but captures stdout and stderr.
"""
function capturedrun(cmd::AbstractCmd)
    if VERSION >= v"1.4"  # maybe works with older Julia
        return _capturedrun_new(cmd)
    else
        return _capturedrun_old(cmd)
    end
end

function _capturedrun_old(cmd::AbstractCmd)
    stdout = Pipe()
    stderr = Pipe()
    prog = pipeline(ignorestatus(cmd); stdout = stdout, stderr = stderr)
    process = run(prog; wait = false)
    close(stdout.in)
    close(stderr.in)
    local out , err
    @sync begin
        errreader = @async read(stderr, String)
        out = read(stdout, String)
        err = fetch(errreader)
    end
    return CompletedProcess(out, err, process)
end

function _capturedrun_new(cmd::AbstractCmd)
    stdout = IOBuffer()
    stderr = IOBuffer()
    process = run(pipeline(ignorestatus(cmd); stdout = stdout, stderr = stderr))
    return CompletedProcess(String(take!(stdout)), String(take!(stderr)), process)
end

function runtests_process(path::AbstractString; env = nothing)
    code = """
    $(Base.load_path_setup_code())
    include(ARGS[1])
    """
    cmd = `$(Base.julia_cmd()) --startup-file=no --compile=min -e $code $path`
    if env !== nothing
        cmd = setenv(cmd, env)
    end
    return capturedrun(cmd)
end

# Infix operator wrapping `ispass` so that the failure case is pretty-printed
⊜(result, yes::Bool) = ispass(result)::Bool == yes

ispass(p::CompletedProcess) = success(p.process)

# To be shown via `@test` when failed:
function Base.show(io::IO, result::CompletedProcess)
    print(io, "⟪")
    show(io, MIME"text/plain"(), result)
    print(io, "⟫")
end

function Base.show(io::IO, ::MIME"text/plain", completed::CompletedProcess)
    println(io, "CompletedProcess:")
    println(io, completed.process.cmd)
    if !isempty(completed.stdout)
        println(io)
        println(io, "stdout:")
        println(io, chomp(completed.stdout))
    end
    if !isempty(completed.stderr)
        println(io)
        println(io, "stderr:")
        println(io, chomp(completed.stderr))
    end
    println(io)
    printstyled(
        io,
        "exit code: $(something(completed.process.exitcode, '?'))",
        color = success(completed.process) ? :green : :red,
    )
end

end  # module
