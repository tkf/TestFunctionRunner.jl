module TestModuleContext

using Test
using ..Utils: @getbool

const IN_CONTEXT = Ref(false)

function module_context(f)
    old = IN_CONTEXT[]
    IN_CONTEXT[] = @getbool("use_module_context")
    try
        f()
    finally
        IN_CONTEXT[] = old
    end
end

function test()
    @test IN_CONTEXT[]
end

end  # module
