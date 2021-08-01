module TestAPI

using Test
using TestFunctionRunner

using ..Samples: SampleSimplePass

function test_run_modules()
    TestFunctionRunner.run([SampleSimplePass, SampleSimplePass])
end

end  # module
