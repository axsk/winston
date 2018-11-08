module WebCrawl

import ..Author, ..Paper

g(::Nothing, i) = nothing #for recursive gets with inbetween misses
g(x, i) = get(x, i, nothing)
g(x, i, j) = g(g(x, i), j)
g(x, k...) = g(g(x, k[1:end-1]...), k[end])

module Crossref
	using PyCall
	import ..WebCrawl: Author, Paper, g

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

	function search(doi::String)
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

	function search(p::Paper)
		if p.doi == nothing
			search(title = p.title, year = p.year, author = string(p.authors))
		else
			search(p.doi)
		end
	end

	function parsedata(items)
		papers = []
		for i in items
			try 
				push!(papers, 
					Paper(year=parseyear(i),
						authors=parseauthors(i),
						title=g(i, "title", 1),
						doi=g(i, "DOI"),
						link = parselinks(i)))
			catch e
				@info "Could not parse $i\nCaught $e"
			end
		end
		return papers
	end

	parseyear(x)    = g(x, "issued", "date-parts", 1)
	parseauthors(x) = map(x->Author(family = g(x, "family"), given = g(x, "given")), get(x, "author", []))
	parselinks(x)    = g(x, "link", 1, "URL")
end

module SemanticScholar
	using HTTP
	using JSON
	import ..WebCrawl: Author, Paper, g
	import ...parseauthorname

	function getdoi(doi)
		global r = HTTP.request("GET", "http://api.semanticscholar.org/v1/paper/$doi?include_unknown_references=true")
		global x = data = JSON.parse(String(r.body))
		w = parsepaper(data)
	end

	function parsepaper(data::Dict)
		Paper(
			year=g(data, "year"),
			authors=parseauthors(data),
			title=g(data, "title"),
			doi=g(data, "doi"),
			references=map(parsepaper, get(data, "references", [])),
			citations=map(parsepaper, get(data, "citations", [])))
	end

	parseauthors(data::Dict) = map(g(data, "authors")) do a
		family, given = parseauthorname(a["name"])
		Author(family=family, given=given)
	end
end

import .Crossref.search

# crawl(doi)
# crawl(; query, year, author, title, limit)

function crawl(args...; kwargs...)
	papers = search(args...; kwargs...)
	map(papers) do p
		try
			s = SemanticScholar.getdoi(p.doi)
			Paper(s, references=s.references, citations=s.citations)
		catch
			p
		end
	end
end



function crawl(p::Paper)
	p = search(p)[1]
	s = SemanticScholar.getdoi(p.doi)
	Paper(p, references=s.references, citations=s.citations)
end

function test()
	crawl("10.1073/pnas.1618455114")
end

end