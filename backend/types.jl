using Parameters
using JSON

Base.map(f, ::Nothing) = nothing

hasval(::Nothing) = false
hasval(::Any) = true

@with_kw struct Paper
    uuid = nothing
    year = nothing
    authors = nothing
    title = nothing
    doi = nothing
    ssid = nothing
    link = nothing
    references = nothing
	citations = nothing
    date = nothing # remove this
    created = nothing
    editlast = nothing
    editfirst = nothing
    usertags = nothing
    function Paper(uuid, year, authors, title, doi, ssid, link, references, citations, date, created, editlast, editfirst, usertags)
        authors = map(Author, authors)
        citations = map(Paper, citations)
        references = map(Paper, references)
        if created == nothing
            created = date
        end
        new(uuid, year, authors, title, doi, ssid, link, references, citations, date, created, editlast, editfirst, usertags)
    end
end

@with_kw struct Author
    uuid = nothing
	family = nothing
    given = nothing
    created = nothing
end

symbolize(d::Dict{String}) = [Symbol(k)=>v for (k,v) in d]

function Paper(p::Paper, d::Dict{String}; kwargs...)
    Paper(p; symbolize(d)..., kwargs...)
end

function Paper(d::Dict{String}; kwargs...)
    Paper(; symbolize(d)..., kwargs...)
end

function Author(d::Dict{String}; kwargs...) 
    if haskey(d, "name")
        d = copy(d)
        family, given = parseauthorname(pop!(d,"name"))
        Author(;symbolize(d)..., family=family, given=given, kwargs...)
    else 
        Author(;symbolize(d)..., kwargs...) # new db version
    end
end

function Author(s::String)
    family, given = parseauthorname(s)
    Author(family=family, given=given)
end

function parseauthorname(s::String)
    try
        i = findprev(" ", s, lastindex(s))
        if i != nothing
            i = first(i)
            given  = s[1:i-1]
            family = s[i+1:end]
        else
            given  = ""
            family = s
        end
        family, given
    catch
        s, nothing
    end
end

Base.string(a::Author) = "$(a.given) $(a.family)"
Base.string(a::Vector{Author}) = join(map(string, a), ", ")

function isvalid(p::Paper)
    any(map(x->ismissing(getfield(p, x)), [:title, :year, :authors])) && return false
    p.authors == [] && return false
    true
end


Base.show(p::Paper) = dump(p)#("$(p.year) - $(reduce(*, p.authors)) - $(p.title)")
#Base.show(io::IO, p::Paper) = show(io, "$(p.year) - $(p.title)")


Node = Union{Paper, Author}
function typedict(x::T, fields=fieldnames(T)) where T 
    Dict(f=>getfield(x, f) for f in fields) 
end

function typedictsparse(x::T) where T
    d = Dict()
    for k in fieldnames(T)
        v = getfield(x, k)
        v == nothing && continue
        d[k] = v
    end
    d
end

JSON.lower(n::Node) = typedictsparse(n)


selector(n::Node) = "$(label(n)) {uuid: $(n.uuid)}"

label(a::Author) = ":Author"
node(a::Author) = typedict(a)
Base.convert(::Type{Author}, d::Dict) = Author(d)

label(p::Paper) = ":Paper"
node(p::Paper) = typedict(p, [:uuid, :year, :ssid, :title, :doi, :link, :created])
Base.convert(::Type{Paper}, d::Dict) = Paper(d)