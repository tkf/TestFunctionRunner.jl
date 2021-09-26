baremodule TestFunctionRunner

function run end
macro run end

module Internal

import ..TestFunctionRunner: @run
using ..TestFunctionRunner: TestFunctionRunner

import LoadAllPackages
import Terminators
using Base: PkgId
using Distributed: @everywhere, nprocs
using Pkg: TOML
using Test: @testset

include("utils.jl")
include("core.jl")

end  # module Internal

Internal.define_docstring()

end  # baremodule TestFunctionRunner
