module TestBeforeAfterHooks

using Test
using TestFunctionRunner.Internal: runtests
using ..XFails: XFailTestSet

module BeforeAfterHooks
using Test
const RUN_BEFORE = Ref(true)
const VALUE = Ref(0)
before_test_module() = RUN_BEFORE[] && (VALUE[] = 1)
after_test_module() = VALUE[] = 0
test() = @test VALUE[] == 1
end  # module BeforeAfterHooks

function test_run_before()
    @test BeforeAfterHooks.VALUE[] == 0
    runtests(BeforeAfterHooks)
    @test BeforeAfterHooks.VALUE[] == 0
end

function test_no_run_before()
    BeforeAfterHooks.RUN_BEFORE[] = false
    try
        @testset XFailTestSet "xfail" begin
            runtests(BeforeAfterHooks)
        end
    finally
        BeforeAfterHooks.RUN_BEFORE[] = true
    end
end

end  # module
