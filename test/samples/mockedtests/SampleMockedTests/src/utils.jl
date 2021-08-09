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

macro getbool(key, default = "true")
    m = @__MODULE__
    esc(:($lowercase($m.@getstr($key, $default)) == "true"))
end

macro getstr(key, default)
    esc(:($_getstr($(QuoteNode(__module__)), $key, $default)))
end

_getstr(__module__::Module, key::AbstractString, default) =
    get(ENV, "$__module__.$key", default)

end  # module
