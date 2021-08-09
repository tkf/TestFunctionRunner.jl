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

module TestShouldTest
using ..Utils: @defmock, @getbool
should_test_module() = @getbool("should_test_module")
@defmock test
end  # module TestShouldTest

module NotATestModule
test() = error("this should not be executed")
end  # module NotATestModule

include("test_module_context.jl")

end  # module SampleMockedTests
