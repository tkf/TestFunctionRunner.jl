module TestMockedTests

using Test
using TestFunctionRunner.Internal: test_functions, test_modules

using ..Samples: SampleMockedTests
using ..Utils: runtests_process, ⊜

const SCRIPT = joinpath(@__DIR__, "../../samples/mockedtests/runtests.jl")

function cleanenv()
    env = Dict{String,String}()
    for (k, v) in ENV
        if startswith(k, "SampleMockedTests.")
            continue
        end
        env[k] = v
    end
    return env
end

function test_runtests_pass()
    if VERSION < v"1.1"
        @test_broken runtests_process(SCRIPT; env = cleanenv()) ⊜ true
        return
    end
    @test runtests_process(SCRIPT; env = cleanenv()) ⊜ true
end

function test_runtests_fail()
    env = cleanenv()
    env["SampleMockedTests.TestNested2.TestNested3.test"] = "false"
    @test runtests_process(SCRIPT; env = env) ⊜ false
end

function test_should_test_module()
    env = cleanenv()
    env["SampleMockedTests.TestShouldTest.test"] = "false"
    @test runtests_process(SCRIPT; env = env) ⊜ false
    env["SampleMockedTests.TestShouldTest.should_test_module"] = "false"
    if VERSION < v"1.1"
        @test_broken runtests_process(SCRIPT; env = env) ⊜ true
        return
    end
    @test runtests_process(SCRIPT; env = env) ⊜ true
end

function test_module_context()
    env = cleanenv()
    env["SampleMockedTests.TestModuleContext.use_module_context"] = "false"
    @test runtests_process(SCRIPT; env = env) ⊜ false
end

function test_discovery()
    @test test_functions(SampleMockedTests) ==
          [SampleMockedTests.test, SampleMockedTests.test_2]
    @test test_modules(SampleMockedTests) == [
        SampleMockedTests.TestModuleContext,
        SampleMockedTests.TestNested,
        SampleMockedTests.TestNested2,
        SampleMockedTests.TestShouldTest,
    ]
end

end  # module
