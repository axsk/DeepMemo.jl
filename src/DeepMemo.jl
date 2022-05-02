using Cassette

Cassette.@context TimeCtx

mutable struct Call2
    method
    source
    time
    in
    out
    history
end

function Cassette.overdub(ctx::TimeCtx, args...)
    subtrace = Any[]
    
    if Cassette.canrecurse(ctx, args...)

        newctx = Cassette.similarcontext(ctx, metadata = subtrace)

        time = @elapsed res = Cassette.recurse(newctx, args...)
        reflection = Cassette.reflect(typeof.(args))
        
        if reflection === nothing  ## this happened e.g. in x^2 with args = (Val{2},)
            hist = []
            @show args
        else
            hist = [reflection]
        end
        
        for c in newctx.metadata
            #push!(hist, c.source)
            #@show c
            #@show c.history
            append!(hist, c.history)
        end
       
        #push!(hist, reflection)


        call = Call2(args[1], reflection, time, args[2:end], res, hist)

        push!(ctx.metadata, call)
        return res
    else
        return Cassette.fallback(ctx, args...)
    end
end

trace = Any[]
x, y, z = 1,2,3
f(x, y, z) = test1(x)

function test1(x)
    test2(x) + test22(x)
end

function test2(x)
    #println("ok")
    2*x + 1
end

function test22(x)
    return x^2
end

Cassette.overdub(TimeCtx(metadata = trace), f, x, y, z)
trace

function checkintegrity(history)
    for ref in history
        nref = Cassette.reflect(Tuple(ref.signature.parameters))
        if !(nref.code_info.code == ref.code_info.code)
            return false
        end
    end
    return true
end
