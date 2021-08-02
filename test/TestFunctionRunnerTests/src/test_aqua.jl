module TestAqua

using Aqua
using TestFunctionRunner

test() = Aqua.test_all(TestFunctionRunner)

end  # module
