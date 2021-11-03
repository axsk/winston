Base.map(f, s::AbstractSet) = Set([f(s) for s in s])

using Revise

include("types.jl")

include("webcrawl.jl")
include("neo.jl")

include("server.jl")
include("cermine.jl")
