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

function addHeader(res)
	headers  = HttpCommon.headers()
	headers["Access-Control-Allow-Origin"] = "*"
	headers["Access-Control-Allow-Methods"] = "*"
	headers["Access-Control-Allow-Headers"] = "*"
	Dict(
	     :headers => headers,
	     :body => res
	     )
end

global d

@app app = (Mux.defaults, Muxify,
	#page("/", req->getpapers() |> json |> addHeader),
	page("/papers", req->(api_search(req[:jq]) |> json |> addHeader)),
	#page("/paper/:id", req->(getpaper(req[:params][:id]) |> json |> addHeader)),
	page("/usertags/:user", req->(getusertags(req[:params][:user]) |> json |> addHeader)),
	page("/editpaper", req->editpaper(req)|>json|>addHeader),
	Mux.notfound())

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