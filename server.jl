using Mux
using HttpCommon

function getpapers(user="Alex")
	tx = transaction(c)
	tx("MATCH (p:Owned)--(a:Author) with p, collect(a.name) as authors
		OPTIONAL MATCH (p)--(tt:Tagging)--(:User {name: \$user}), (tt)--(t:Tag) 
		return p.year as year, p.title as title, authors, collect(t.name) as tags, p.uuid",
	   "user" => user)
	r = commit(tx)
    [let row = rr["row"] 
		 Dict("Year"=>row[1], "Title"=>row[2], "Authors"=>join(row[3], ", "), "Tags"=>join(row[4], ", "), "uuid"=>row[5])
	 end
	 for rr in r.results[1]["data"]]
end

function getpaper(id)
	tx = transaction(c)
	tx("MATCH (p:Paper {uuid:\$uuid})
	   OPTIONAL MATCH (p)--(tt:Tagging)--(t:Tag), (tt)--(:User)
	   with p, collect(t) as tags
	   OPTIONAL MATCH (p)--(a:Author)
	   RETURN p, collect(a), tags",
	   "uuid" => id)
	r = commit(tx)
	row = r.results[1]["data"][1]["row"]
	
end

function synctags(user, pid, tags)
	@show dbtags = cypherQuery(c,
		"MATCH (u:User {name: \$user})--(tt:Tagging)--(p:Paper {uuid: \$pid}),
		       (tt)--(t:Tag)
		RETURN t.name", "user" => user, "pid" => pid)

	if size(dbtags, 1) > 0
		dbtags = dbtags[1]
	else
		dbtags = []
	end

	remove = setdiff(dbtags, tags)
	add    = setdiff(tags, dbtags)

	tx = transaction(c)
	# add
	tx("MATCH (u:User {name: \$user}),
		      (p:Paper {uuid: \$pid})
		UNWIND \$tags as tag
	    MERGE (t:Tag  {name: tag})
	    CREATE (u)-[:tag]->(tt:Tagging {date: datetime()})-[:tag]->(p),
	           (tt)-[:tag]->(t)",
	    "user" => user, "pid" => pid, "tags" => add)

	# remove
	tx("MATCH (u:User {name: \$user}),
		      (p:Paper {uuid: \$pid})
		UNWIND \$tags as tag
		MATCH (t:Tag {name: tag}),
		      (u)--(tt)--(p), (tt)--(t)
		DETACH DELETE tt",
		"user" => user, "pid" => pid, "tags" => remove)
	commit(tx)
end


## Middleware

function addHeaderMux(app, req)
	res = app(req)
	@show typeof(res)
	@show req
	addHeader(res)
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

@app app = (Mux.defaults,
	    page("/", req->getpapers() |> json |> addHeader),
	    page("/paper/:id", req->(getpaper(req[:params][:id]) |> json |> addHeader)),
	    page("/editpaper", req->editpaper(req)|>json|>addHeader),
	    Mux.notfound())

function editpaper(req)
	if length(req[:data]) > 0
		s = String(req[:data])
		global d
		@show d = JSON.parse(s)	
		synctags("Alex", d["pid"], d["tags"])
	end
	return ""
end

global served

if !isdefined(Main, :served)
	served=true
end

if !served
	served = true
	serve(app)
end
