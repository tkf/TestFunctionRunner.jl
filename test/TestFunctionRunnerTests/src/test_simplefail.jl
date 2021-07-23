module TestSimpleFail

using ..Utils: runtests_process, ⊜

using Test

const SCRIPT = joinpath(@__DIR__, "../../samples/simplefail/runtests.jl")

test() = @test runtests_process(SCRIPT) ⊜ false

end  # module
