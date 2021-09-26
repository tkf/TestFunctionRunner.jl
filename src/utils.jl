if VERSION <= v"1.1"
    isnothing(x) = x === nothing
end

function define_docstring()
    path = joinpath(@__DIR__, "..", "README.md")
    include_dependency(path)
    doc = read(path, String)
    # doc = replace(doc, r"^```julia"m => "```jldoctest README")
    @eval TestFunctionRunner $Base.@doc $doc TestFunctionRunner
end
