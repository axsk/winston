Base.map(f, s::AbstractSet) = Set([f(s) for s in s])

using Revise

includet("types.jl")

includet("webcrawl.jl")
includet("neo.jl")

includet("server.jl")
includet("cermine.jl")