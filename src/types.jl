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
    link = nothing
    references = nothing
	citations = nothing
    date = nothing # remove this
    created = nothing
    usertags = nothing
    function Paper(uuid, year, authors, title, doi, link, references, citations, date, created, usertags)
        authors = map(Author, authors)
        citations = map(Paper, citations)
        references = map(Paper, references)
        new(uuid, year, authors, title, doi, link, references, citations, date, created, usertags)
    end
end

@with_kw struct Author
    uuid = -nothing
	family = nothing
	given = nothing
end

symbolize(d::Dict{String}) = [Symbol(k)=>v for (k,v) in d]

function Paper(d::Dict{String}; kwargs...)
    Paper(;symbolize(d)..., kwargs...)
end

function Author(d::Dict{String}; kwargs...) 
    if haskey(d, "name")
        family, given = parseauthorname(pop!(d,"name"))
        Author(;symbolize(d)..., family=family, given=given, kwargs...)
    else 
        Author(;symbolize(d)..., kwargs...) # new db version
    end
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

string(a::Author) = "$(a.given) $(a.family)"
string(a::Vector{Author}) = join(map(string, a), ", ")

function isvalid(p::Paper)
    any(map(x->ismissing(getfield(p, x)), [:title, :year, :authors])) && return false
    p.authors == [] && return false
    true
end


Base.show(p::Paper) = dump(p)#("$(p.year) - $(reduce(*, p.authors)) - $(p.title)")
#Base.show(io::IO, p::Paper) = show(io, "$(p.year) - $(p.title)")