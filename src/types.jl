using Parameters

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
end

@with_kw struct Author
	family = missing
	given = missing
end

symbolize(d::Dict{String}) = [Symbol(k)=>v for (k,v) in d]

Paper(d::Dict{String}, kwargs...) = Paper(;symbolize(d)..., kwargs...)
Author(d::Dict{String}) = Author(;symbolize(d)...)
Author(; name::String=missing) = parseauthorname(name)

function parseauthorname(s::String)
    i = findprev(" ", s, lastindex(s))
    if i != nothing
        i = first(i)
        given  = s[1:i-1]
        family = s[i+1:end]
    else
        given  = ""
        family = s
    end
    Author(family, given)	
end

string(a::Author) = "$(a.given) $(a.family)"
string(a::Vector{Author}) = join(map(string, a), ", ")

function isvalid(p::Paper)
    any(map(x->ismissing(getfield(p, x)), [:title, :year, :authors])) && return false
    p.authors == [] && return false
    true
end