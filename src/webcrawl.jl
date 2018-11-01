module WebCrawl

struct Author
	family
	given 
end

mutable struct Work
	year
	authors
	title
	doi
	link
	references
	citations
end


Base.map(f, ::Nothing) = nothing

g(::Nothing, i) = nothing
g(x, i) = get(x, i, nothing)
g(x, i, j) = g(g(x, i), j)
g(x, k...) = g(g(x, k[1:end-1]...), k[end])

module Crossref
	using PyCall
	import ..WebCrawl: Author, Work, g

	@pyimport habanero
	cr = habanero.Crossref()
	getworks = cr[:works]

	function search(;query=nothing, year=nothing, author=nothing, title=nothing, limit=1)
		local data
		try
			data = getworks(
				query       = query,
				query_title = title, 
				query_author = author, 
				query_bibliographic = year,
				limit = limit,
				select = ["issued", "author", "link", "DOI", "title"])
			data = data["message"]["items"]
		catch e
			@info "Error on fetchin Crossref search $e"
			data = []
		end

		parsedata(data)
	end

	function search(doi)
		local data
		try
			data = getworks(ids=doi)["message"]
			isa(data, Dict) && (data = [data])
		catch e
			@info "Error on fetching Crossref DOI"
			data = []
		end

		parsedata(data)
	end

	function parsedata(items)
		works = []
		for i in items
			try 
				year    = parseyear(i)
				authors = parseauthors(i)
				title   = g(i, "title", 1)
				doi     = g(i, "DOI")
				link    = parselinks(i)
				push!(works, Work(year, authors, title, doi, link, nothing, nothing))
			catch e
				@info "Could not parse $i\nCaught $e"
			end
		end
		return works
	end

	function getdoi()
	end

	parseyear(x)    = g(x, "issued", "date-parts", 1)
	parseauthors(x) = map(x->Author(g(x, "family"), g(x, "given")), g(x, "author"))
	parselinks(x)    = g(x, "link", 1, "URL")
end

module SemanticScholar
	using HTTP
	using JSON
	import ..WebCrawl: Author, Work, g

	function getdoi(doi)
		try 
			global r = HTTP.request("GET", "http://api.semanticscholar.org/v1/paper/$doi?include_unknown_references=true")
			global x=data = JSON.parse(String(r.body))
			w = parsepaper(data)
		catch e
			@show e
			Work(nothing, nothing, nothing, doi, nothing, nothing, nothing)
		end
	end

	function parsepaper(data::Dict)
		Work(
			g(data, "year"),
			parseauthors(data),
			g(data, "title"),
			g(data, "doi"),
			nothing,
			map(parsepaper, g(data, "references")),
			map(parsepaper, g(data, "citations")))
	end

	parseauthors(data::Dict) = map(a->parseauthor(a["name"]), g(data, "authors"))

	function parseauthor(s::AbstractString)
		i = length(s)
		while s[i] != ' '
			i -= 1
		end
		given  = s[1:i-1]
		family = s[i+1:end]
		Author(family, given)
	end
end

import .Crossref.search

function crawl(args...; kwargs...)
	c = search(args...; kwargs...)
	s = map(c->SemanticScholar.getdoi(c.doi), c)
	for i in 1:length(c)
		c[i].references = s[i].references
		c[i].citations  = s[i].citations
	end
	c
end

end
