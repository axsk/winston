using Mux
using HttpCommon

## Middleware

# create REST middleware: headers, json output, jsonparse input

# TODO: use this
function MuxHeaders(app, req)
	res = app(req)
	addHeader(res)
end

function Muxify(app, req)
	req[:query] = HttpCommon.parsequerystring(req[:query])
	jq = get(req[:query], "json", "{}") # parse ?json= field
	req[:jq] = JSON.parse(jq)
	addCORS(app(req))
end

addHeader(res) = addCORS(res)

function addCORS(res)
	res = Dict(:body => res, :headers => HTTP.Headers())
	addCORS(res)
end

function addCORS(res::Dict)
	if haskey(res, :headers) 
		for x in ["Origin", "Methods", "Headers"]
			push!(res[:headers], "Access-Control-Allow-$x" => "*")
		end
		return res
	else
		println("whats going on")
		@show res
	end
end

global d

pdffile =  "/Users/alex/Documents/Paper/PhD/ihpFBSDE.pdf"

using HTTP

pdfresponse(data::Vector{UInt8}) = Dict(
	:headers => HTTP.Headers([
		"Content-Type" => "application/pdf"]),
	:body => data)

idhandler(f) = req->(f(convert(String, req[:params][:id])) |> json)


using Base64: stringmime
@app app = (Mux.defaults, Muxify,
	#page("/", req->getpapers() |> json |> addHeader),
	page("/search", req->handleSearch(req)),
	page("/author/:id", idhandler(getauthor)),
	page("/paper/:id", req->handlePaper(req)),
	page("/paper/:id/references", idhandler(loadrefs)),
	page("/paper/add/doi", req->paperAddDoi(req)),
	#page("/paper/:id", req->(getpaper(req[:params][:id]) |> json |> addHeader)),
	page("/usertags/:user", req->(getusertags(req[:params][:user]) |> json)),
	page("/editpaper", req->editpaper(req)|>json),
	page("/pdf/:id", req->pdfresponse(loadpdf(req[:params][:id]))),
	page("/uploadpaper/:id", req -> 
		if req[:method] == "OPTIONS"
			""
		else
			pid = req[:params][:id]
			pdf = req[:data]
			savepdf(pid, pdf)
			""
		end),
	page("/comment", req->(
		if req[:method] == "OPTIONS"
			""
		elseif req[:method] == "PUT"
			mergehighlights(req)
		elseif req[:method] == "GET"
			gethighlights(req[:query])
		end
		)),
	Mux.notfound())

function paperAddDoi(req)
	method = req[:method]
	if method == "OPTIONS" 
		return ""
	elseif method == "GET"
		doi = req[:query]["doi"]
		p = WebCrawl.Crossref.search(doi)[1]
		syncpaper(p, "Alex")
	end
end

function handleSearch(req)
	api_search(req[:jq]) |> json
end

function handlePaper(req)
	method = req[:method]
	if method == "OPTIONS"
		"puthere"
	elseif method == "GET"
		loaduuid(convert(String, req[:params][:id])) |> json
	elseif method == "POST"
		p = create(Paper()) |> json
	elseif method == "PUT"
		editpaper(req) |> json
	end
end

function mergehighlights(req)
	s = JSON.parse(String(req[:data]))
	map(get(s, "highlights", [])) do h
		puthighlight(s["pid"], "Alex", h) end
	map(get(s, "notes", [])) do n
		putnote(s["pid"], "Alex", n) end
	""
end

function gethighlights(q)
	Dict("highlights" => gethighlights(q["pid"], "Alex"),
		 "comments"   => getcomments(q["pid"], "Alex"))|> json
end

function api_search(d::Dict)
	api_search(d["query"], d["user"], d["usertags"])
end

function editpaper(req, user="Alex")
	if length(req[:data]) > 0
		s = String(req[:data])
		d = JSON.parse(s)
		p = Paper(d)
		return syncpaper(p, user)
	end
	return ""
end

# autoserve
global autoserve
!isdefined(Main, :autoserve) && (autoserve=false) # change this to true for autoserve

if autoserve
	serve(app)
	autoserve = false
end