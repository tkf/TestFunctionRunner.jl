module TestMultiplePackages

const SCRIPT = joinpath(@__DIR__, "../../samples/multiplepackages/runtests.jl")

test() = include(SCRIPT)

end  # module
