using Mux
using HttpCommon

function getpapers(user="Alex")
	tx = transaction(c)
	tx("MATCH (p:Owned)--(a:Author) OPTIONAL MATCH (p)--(tt:Tagging)--(:User {name: \$user}), (tt)--(t:Tag) return p.year as year, p.title as title, collect(a.name) as authors, collect(t.name) as tags, p.uuid",
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
	   OPTIONAL MATCH (p)--(a:Author)
	   RETURN p, collect(a), collect(t)",
	   "uuid" => id)
	r = commit(tx)
	row = r.results[1]["data"][1]["row"]
	
end

function synctags(user, pid, tags)
	dbtags = cypherQuery(c,
		"MATCH (u:User {name: \$user})--(tt:Tagging)--(p:Paper {\$pid}),
		       (tt)--(t:Tag)
		RETURN t.name", "user" => user, "pid" => pid)[1]

	remove = setdiff(dbtags, tags)
	add    = setdiff(tags, dbtags)

	tx = transaction(c)
	# add
	tx("MATCH (u:User {name: \$user}),
		      (p:Paper {\$pid})
		UNWIND \$tags as tag
	    MERGE (t:Tag  {name: tag})
	    CREATE (u)-[:tag]->(tt:Tagging {date: datetime()})-[:tag]->(p),
	           (tt)-[:tag]->(t)",
	    "user" => user, "year" => p.year, "title" => p.title, "tags" => add)

	# remove
	tx("MATCH (u:User {name: \$user}),
		      (p:Paper {\$pid})
		UNWIND \$tags as tag
		MATCH (t:Tag {name: tag}),
		      (u)--(tt)--(p), (tt)--(t)
		DETACH DELETE tt",
		"user" => user, "year" => p.year, "title" => p.title, "tags" => remove)
	commit(tx)
end


## Middleware

function addHeader(app, req)
	res = app(req)
	@show typeof(res)
	headers  = HttpCommon.headers()
	headers["Access-Control-Allow-Origin"] = "*"
	println("fine")
	Dict(
	     :headers => headers,
	     :body => res
	     )
end

@app app = (Mux.defaults, addHeader,
	    page("/", req->getpapers() |> json),
	    page("/paper/:id", req->getpaper(req[:params][:id]) |> json),
	    Mux.notfound())

global served

if !isdefined(Main, :served)
	served=true
end

if !served
	served = true
	serve(app)
end
