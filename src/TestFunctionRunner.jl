baremodule TestFunctionRunner

module Internal

using ..TestFunctionRunner: TestFunctionRunner

include("internal.jl")

end  # module Internal

end  # baremodule TestFunctionRunner
