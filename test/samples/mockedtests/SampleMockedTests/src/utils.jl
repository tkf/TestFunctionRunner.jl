module Utils

using Test

macro defmock(name::Symbol)
    esc(:($name() = $mock($(QuoteNode(__module__)), $(QuoteNode(name)))))
end

function mock(__module__::Module, name::Symbol)
    # The result of test `$__module__.$name` can be controlled by setting
    # Setting ENV["SampleMockedTests.$name"].
    @test lowercase(get(ENV, "$__module__.$name", "true")) == "true"
end

end  # module
