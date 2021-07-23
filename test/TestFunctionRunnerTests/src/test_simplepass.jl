module TestSimplePass

const SCRIPT = joinpath(@__DIR__, "../../samples/simplepass/runtests.jl")

test() = include(SCRIPT)

end  # module
