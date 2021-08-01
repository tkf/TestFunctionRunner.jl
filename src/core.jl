"""
    TestFunctionRunner.run(module::Module)
    TestFunctionRunner.run(modules::AbstractVector)

Run tests defined in a `module`.

This function discovers "test functions" in `module` and its "test modules"
recursively.  Test functions are nullary functions named `test` or nullary
functions whose name start with `test_`.  Test modules are the sub-modules
whose name starts with "Test" followed by a capital letter.
"""
TestFunctionRunner.run

function TestFunctionRunner.run(m::Module; prepare_distributed::Bool = true, kwargs...)
    with_project(m) do
        if prepare_distributed
            load_everywhere(m)
        else
            prepare_local(m)
        end
        testset = @testset "$(nameof(m))" begin
            runtests(m; kwargs...)
        end
        Success(testset)
    end
end

function TestFunctionRunner.run(modules::AbstractVector; kwargs...)
    for m in modules
        TestFunctionRunner.run(m::Module; kwargs...)
    end
end

struct Success
    testset::Any
end

function Base.show(io::IO, ::MIME"text/plain", ::Success)
    print(io, "Success: 🎉 All test passed")
    # TODO: print more info
end

function find_project_file(dir)
    p = joinpath(dir, "JuliaProject.toml")
    isfile(p) && return p
    p = joinpath(dir, "Project.toml")
    isfile(p) && return p
    return nothing
end

function root_module(m::Module)
    while true
        p = parentmodule(m)
        m === p && return m
        m = p
    end
end

function projectfile(m::Module)
    dir = dirname(dirname(pathof(root_module(m))))
    p = find_project_file(dir)
    p === nothing && error("cannot find the project for module $m")
    return p
end

function is_in_path(m::Module)
    project = projectfile(m)
    paths = Base.load_path()
    project in paths && return true
    realproject = realpath(project)
    realproject in paths && return true
    matches(path) = path == project || path == realproject
    return any(paths) do path
        matches(path) || matches(realpath(path))
    end
end

function with_project(f, m::Module)
    is_in_path(m) && return f()
    load_path = copy(LOAD_PATH)
    push!(LOAD_PATH, projectfile(m))
    try
        f()
    finally
        append!(empty!(LOAD_PATH), load_path)
    end
end

function load_everywhere(m::Module)
    pkgid = Base.PkgId(m)
    prepare_local(m)
    nprocs() == 1 && return
    @everywhere append!(empty!(LOAD_PATH), $(copy(LOAD_PATH)))
    @everywhere Base.require($pkgid)
    @everywhere $prepare_local($m)
end

function prepare_local(m::Module)
    LoadAllPackages.loadall(projectfile(m))
end

function should_test(m::Module)
    f = try
        m.should_test_module
    catch
        return true
    end
    return f()::Bool
end

function runtests(m::Module; recursive::Bool = true)
    should_test(m) || return
    @debug "Testing module: `$m`"
    @testset "$f" for f in test_functions(m)
        @debug "Testing function: `$m.$f`"
        f()
    end
    recursive || return
    @testset "$(nameof(sub))" for sub in test_modules(m)
        runtests(sub)
    end
end

is_test_function(name::Symbol) = name === :test || startswith(string(name), "test_")
is_test_module(name::Symbol) = match(r"^Test[A-Z]", string(name)) !== nothing

function test_functions(m::Module)
    tests = map(names(m, all = true)) do n
        is_test_function(n) || return nothing
        f = getproperty(m, n)
        f !== m || return nothing
        if f isa Type
            t = f
        else
            t = typeof(f)
        end
        parentmodule(t) === m || return nothing
        applicable(f) || return nothing  # removed by Revise?
        return f
    end
    filter!(!isnothing, tests)
    sort!(tests, by = string ∘ nameof)
    return tests
end

function test_modules(root::Module)
    modules = Module[]
    for n in names(root, all = true)
        m = getproperty(root, n)
        m isa Module || continue
        m === root && continue
        parentmodule(m) === root || continue
        is_test_module(nameof(m)) || continue
        push!(modules, m)
    end
    sort!(modules, by = string ∘ nameof)
    return modules
end

"""
    TestFunctionRunner.@run()

Run tests defined in the package `@__DIR__/\$TestPackage/src/\$TestPackage.jl`.

# Keyword Arguments

- `paths::AbstractVector{<:AbstractString}`: Additional load paths. Relative
  paths are resolved with respect to the parent direcotry of the current file.
  Example: `TestFunctionRunner.@run(paths = ["../benchmark/MyBenchmarks/"])`.

- `packages::AbstractVector{<:AbstractString}`: Specify packages to be tested by
  relative paths.
"""
macro run(options...)
    kwargs = map(assignment_as_kw, options)
    esc(:($at_run_impl($(QuoteNode(__source__)), $(QuoteNode(__module__)); $(kwargs...))))
end

function assignment_as_kw(ex)
    if Meta.isexpr(ex, :(=), 2)
        return Expr(:kw, ex.args...)
    end
    error("a key-value pair (`k = v`) is expected; got: $ex")
end

function at_run_impl(
    __source__::LineNumberNode,
    __module__::Module;
    paths::AbstractVector{<:AbstractString} = String[],
    packages::Union{AbstractVector{<:AbstractString}, Nothing} = nothing,
    kwargs...,
)
    testdir = dirname(string(__source__.file))
    paths = joinpath.(testdir, String.(paths))
    if packages === nothing
        pkgid, project = find_test_package(testdir)
        pushfirst!(paths, project)
        m = load_test_package(pkgid, paths)
    else
        m = map(packages) do pkgpath
            local project = joinpath(testdir, pkgpath)
            local pkgid = pkgid_from_project_path(project)
            load_test_package(pkgid, [project; paths])
        end
    end
    Base.invokelatest(TestFunctionRunner.run, m; kwargs...)
end

function load_test_package(pkgid::PkgId, paths::Vector{String})::Module
    missing_paths = setdiff!(map(abspath, paths), LOAD_PATH)
    try
        return Base.require(pkgid)
    catch
        isempty(missing_paths) && rethrow()
        append!(LOAD_PATH, missing_paths)
    end
    @debug "Try loading `$pkgid` again after `LOAD_PATH` hack..." LOAD_PATH
    return Base.require(pkgid)
end

function find_test_package(dir::AbstractString)
    projects = Tuple{Base.PkgId,String}[]
    for n in readdir(dir)
        subdir = joinpath(dir, n)
        isdir(subdir) || continue

        path = find_project_file(subdir)
        path === nothing && continue

        toml = TOML.parsefile(path)
        name = get(toml, "name", nothing)
        uuid = get(toml, "uuid", nothing)
        name === nothing && continue
        uuid === nothing && continue
        isfile(subdir, "src", name * ".jl") || continue

        pkgid = PkgId(Base.UUID(uuid), name)
        push!(projects, (pkgid, path))
    end
    if isempty(projects)
        error("test package not found at: $dir")
    elseif length(projects) > 1
        error("multiple packages found at: $dir")
    end
    return projects[1]
end

function pkgid_from_project_path(path)
    if isdir(path)
        project = find_project_file(path)
    else
        project = path
    end
    toml = TOML.parsefile(project)
    name = toml["name"]::String
    uuid = toml["uuid"]::String
    return PkgId(Base.UUID(uuid), name)
end

#=
abstract type Testable end

struct TestModule <: Testable
    m::Module
    tests::Vector{Testable}
end

struct TestFunction <: Testable
    f::Any
end

testname(t::TestModule) = nameof(t.m)
testname(t::TestFunction) = nameof(t.f)

function TestFunctionRunner.run(testable::TestModule)
    @testset "$(testname(t))" for t in testable.tests
        TestFunctionRunner.run(t)
    end
end

TestFunctionRunner.run(testable::TestFunction) = testable.f()

TestFunctionRunner.collect(m::Module) = TestModule(m, discover(m))

function discover(m::Module)
    for n in names(root, all = true)
        m = getproperty(root, n)
        m isa Module || continue
        m === root && continue
        startswith(string(nameof(m)), "Test") || continue
        push!(modules, m)
    end
end
=#
