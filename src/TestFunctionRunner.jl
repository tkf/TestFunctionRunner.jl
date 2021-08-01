baremodule TestFunctionRunner

function run end
macro run end

module Internal

import ..TestFunctionRunner: @run
using ..TestFunctionRunner: TestFunctionRunner

import LoadAllPackages
using Base: PkgId
using Distributed: @everywhere, nprocs
using Pkg: TOML
using Test: @testset

include("utils.jl")
include("core.jl")

end  # module Internal

end  # baremodule TestFunctionRunner
