module SampleMockedTests

include("utils.jl")
using .Utils: @defmock

@defmock test
@defmock test_2

module TestNested
using ..Utils: @defmock
@defmock test
@defmock test_2
end  # module TestNested

module TestNested2
module TestNested3
using ...Utils: @defmock
@defmock test
@defmock test_2
end  # module TestNested3
end  # module TestNested2

module NotATestModule
test() = error("this should not be executed")
end  # module NotATestModule

end  # module SampleMockedTests
