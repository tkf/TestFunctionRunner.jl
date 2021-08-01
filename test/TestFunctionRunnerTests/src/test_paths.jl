module TestPaths

using ..Utils: runtests_process, ⊜

using Test

const SCRIPT = joinpath(@__DIR__, "../../samples/paths/runtests.jl")

test() = @test runtests_process(SCRIPT) ⊜ true

end  # module
