module XFails

using Test

struct XFailTestSet <: Test.AbstractTestSet
    ts::Test.AbstractTestSet

    XFailTestSet(ts::Test.AbstractTestSet) = new(ts)
end

function XFailTestSet(args...; kwargs...)
    ts = Test.get_testset()
    if ts isa XFailTestSet
        ts = ts.ts
    end
    TestSetType = typeof(ts)
    @assert !(TestSetType isa XFailTestSet)
    XFailTestSet(TestSetType(args...; kwargs...))
end

function Test.finish(ts::XFailTestSet)
    if Test.get_testset_depth() != 0
        parent_ts = Test.get_testset()
        if parent_ts isa XFailTestSet
            Test.record(parent_ts.ts, ts.ts)
            return ts.ts
        end
    end
    return Test.finish(ts.ts)
end

Test.record(ts::XFailTestSet, result::Test.Pass) = Test.record(
    ts.ts,
    Test.Fail(
        Symbol(:xfail_, result.test_type),
        result.orig_expr,
        result.data,
        result.value,
        LineNumberNode(0, Symbol("<unknown>")),
    ),
)
Test.record(ts::XFailTestSet, result::Test.Fail) = Test.record(
    ts.ts,
    Test.Pass(
        Symbol(:xfail_, result.test_type),
        result.orig_expr,
        result.data,
        result.value,
    ),
)
Test.record(ts::XFailTestSet, result::Test.Error) = Test.record(ts.ts, result)

end  # module
