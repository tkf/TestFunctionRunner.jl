try
    using TestFunctionRunnerTests
    true
catch
    false
end || begin
    let path = joinpath(@__DIR__, "TestFunctionRunnerTests")
        path in LOAD_PATH || push!(LOAD_PATH, path)
    end
    using TestFunctionRunnerTests
end
