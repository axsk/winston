using Parameters
using JSON

JSON.lower(::Missing) = nothing

Base.map(f, ::Missing) = missing
Base.map(f, ::Nothing) = nothing

@with_kw struct Paper
    uuid = missing
    year = missing
    authors = missing
    title = missing
    doi = missing
    link = missing
    references = missing
	citations = missing
    date = missing
    usertags = missing
    function Paper(uuid, year, authors, title, doi, link, references, citations, date, usertags)
        authors = map(Author, authors)
        citations = map(Paper, citations)
        references = map(Paper, references)
        new(uuid, year, authors, title, doi, link, references, citations, date, usertags)
    end
end

@with_kw struct Author
    uuid = missing
	family = missing
	given = missing
end

symbolize(d::Dict{String}) = [Symbol(k)=>v for (k,v) in d]

function Paper(d::Dict{String}; kwargs...)
    Paper(;symbolize(d)..., kwargs...)
end

Author(d::Dict{String}) = if haskey(d, "name") 
        Author(d["name"])  # old db version
    else 
        Author(;symbolize(d)...) # new db version
    end

Author(name::String) = parseauthorname(name)

function parsepaperauthor(p::Dict, as::Vector)::Paper
	as = map(Author, as)
	p  = Paper(p, authors = as)
end

# remove this
#Author(; name::String=missing) = parseauthorname(name)

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
        Author(family = family, given = given)	
    catch
        Author(family = s)
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