module DeepMemo

using Cassette

Cassette.@context TimeCtx

mutable struct MethodCall
    args
    time
    result
    reflection
    history
end

CACHE = Dict()

BLACKLIST = [Base, Core]
MODS = []

function inblacklist(mod)
    x = 0
    while mod != Main

        if mod in BLACKLIST
            return true
        end
        push!(MODS, mod)
        modn = parentmodule(mod)
        modn == mod && return false
        mod = modn
    end
end


@generated function Cassette.overdub(ctx::TimeCtx, args...)
    reflection = Cassette.reflect(args)
    if isa(reflection, Cassette.Reflection)
        if ! inblacklist(reflection.method.module)
            return :(myoverdub(ctx, args...))
        end
    end
    return :(Cassette.recurse(ctx, args...))
end

function myoverdub(ctx::TimeCtx, args...)

    CACHE::Dict
    if haskey(CACHE, args) && true
        call = CACHE[args]
        if checkhash(call)
            println("found cache $args")
            return call.result
        else
            println("cache invalidated $args")
            delete!(CACHE, args)
        end
    end

    if Cassette.canrecurse(ctx, args...)
        return MethodCall(ctx, args)
    else
        return Cassette.fallback(ctx, args...)
    end
end


function MethodCall(ctx, args)
    newctx = Cassette.similarcontext(ctx, metadata = Meta(args))

    time = @elapsed result = Cassette.recurse(newctx, args...)
    #@show args, newctx.metadata.deps
    #@show args, ctx.metadata, newctx.metadata
    deps = union!(ctx.metadata.deps, newctx.metadata.deps) # add (sub-)calls to parent ctx

    call = MethodCall(args, time, result, nothing, deps)

    ctx.metadata.cached[1] += newctx.metadata.cached[1]

    if time - ctx.metadata.cached[1] >= -100
        #println("adding to cache ", call.args)
        storehash!(call)
        ctx.metadata.cached[1] = time
        push!(CACHE, (call.args)=>call)
    end

    return result
end

function storehash!(call)
    call.reflection = [(sig, which(sig)) for sig in call.history]
end

function checkhash(call)
    checkworld(call)
end

function checkworld(call)
    all(call.reflection) do (sig, meth)
        old = meth
        new = which(sig)
        new.primary_world == old.primary_world
    end
end

Meta() = (; deps=Set{Type}(), cached=[0.])
Meta(args) = (; deps=Set{Type}((typeof(args), )), cached=[0.])

global CACHE = Dict()

reset() = global CACHE=Dict()

f(x) = test1(x)
function test()
    #global CACHE = Dict()
    trace = Meta()
    res = Cassette.overdub(TimeCtx(metadata = Meta()), f, collect(1:3))
    res = Cassette.overdub(TimeCtx(metadata = Meta()), f, 4)
    res = Cassette.overdub(TimeCtx(metadata = Meta()), map, f, 1:5)
    res, trace
end

function test1(x)
    test2(x) + test22(x)
end

function test2(x)
    #println("ok")
    2*x .+ 2
end

function test22(x)
    sleep(0.1)
    return x.^2
end

function checkintegrity(history)
    for ref in history
        nref = Cassette.reflect(Tuple(ref.signature.parameters))
        if !(nref.code_info.code == ref.code_info.code)
            return false
        end
    end
    return true
end

end # module
