using Mux
using HttpCommon

## Middleware

# create REST middleware: headers, json output, jsonparse input

# TODO: use this
function MuxHeaders(app, req)
	res = app(req)
	@show typeof(res)
	@show req
	addHeader(res)
end

function Muxify(app, req)
	req[:query] = HttpCommon.parsequerystring(req[:query])
	jq = get(req[:query], "json", "{}") # parse ?json= field
	req[:jq] = JSON.parse(jq)
	app(req)
end

addHeader(res) = addCORS(res)
	#=
	return addCORS(res)
	headers  = HttpCommon.headers()
	headers["Access-Control-Allow-Origin"] = "*"
	headers["Access-Control-Allow-Methods"] = "*"
	headers["Access-Control-Allow-Headers"] = "*"
	Dict(
	     :headers => headers,
	     :body => res
		 )
end
	=#

function addCORS(res)
	res = Dict(:body => res, :headers => HTTP.Headers())
	addCORS(res)
end

function addCORS(res::Dict)
	for x in ["Origin", "Methods", "Headers"]
		push!(res[:headers], "Access-Control-Allow-$x" => "*")
	end
	res
end

global d

pdffile =  "/Users/alex/Documents/Paper/PhD/ihpFBSDE.pdf"

using HTTP

pdfresponse(data::Vector{UInt8}) = Dict(
	:headers => HTTP.Headers([
		"Content-Type" => "application/pdf",
		"Access-Control-Allow-Origin" => "*",
		"Access-Control-Allow-Methods" => "*",
		"Access-Control-Allow-Headers" => "*"]),
	:body => data)


using Base64: stringmime
@app app = (Mux.defaults, Muxify,
	#page("/", req->getpapers() |> json |> addHeader),
	page("/papers", handlePaper),
	#page("/paper/:id", req->(getpaper(req[:params][:id]) |> json |> addHeader)),
	page("/usertags/:user", req->(getusertags(req[:params][:user]) |> json |> addHeader)),
	page("/editpaper", req->editpaper(req)|>json|>addHeader),
	page("/pdf/:id", req->pdfresponse(loadpdf(req[:params][:id]))),
	page("/uploadpaper/:id", req -> 
		if req[:method] == "OPTIONS"
			""|>addHeader
		else
			@show pid = req[:params][:id]
			pdf = req[:data]
			savepdf(pid, pdf)
			""|>addHeader
		end),
	page("/comment", req->(
		if req[:method] == "OPTIONS"
			""|>addHeader
		elseif req[:method] == "PUT"
			mergehighlights(req)
		elseif req[:method] == "GET"
			@show req
			gethighlights(req[:query])
		end
		)),
	Mux.notfound())


function handlePaper(req)
	method = req[:method]
	if method == "GET"
		req->(api_search(req[:jq]) |> json)
	elseif method == "POST"
		req -> create(Paper()) |> json
	elseif method == "PUT"
		req -> editpaper(req) |> json
	end
end

function mergehighlights(req)
	s = JSON.parse(String(req[:data]))
	map(get(s, "highlights", [])) do h
		puthighlight(s["pid"], "Alex", h) end
	map(get(s, "notes", [])) do n
		putnote(s["pid"], "Alex", n) end
	""|>addHeader
end

function gethighlights(q)
	Dict("highlights" => gethighlights(q["pid"], "Alex"),
		 "comments"   => getcomments(q["pid"], "Alex"))|> json |> addHeader
end

function api_search(d::Dict)
	api_search(d["query"], d["user"], d["usertags"])
end

function editpaper(req, user="Alex")
	if length(req[:data]) > 0
		s = String(req[:data])
		d = JSON.parse(s)
		p = Paper(d)
		syncpaper(p, user)
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