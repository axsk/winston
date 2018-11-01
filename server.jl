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

function api_search(query, user, usertags)
	@show query, user, usertags
	tx = transaction(c)
	tx( "MATCH (p:Paper)--(a:Author) with p, collect(a.name) as authors
		 OPTIONAL MATCH (p)--(tt:Tagging)--(u:User {name: \$user}), 
		 	(tt)--(t:Tag)
		 WITH p, authors, collect(t.name) as tags
		 WHERE ALL(tag in \$usertags WHERE tag in tags)
		 AND p.title =~ \$regex
		 RETURN p.year, p.title, authors, tags, p.uuid",

		"regex" => "(?i).*" * query * ".*", 
		"user" => user, 
		"usertags" => usertags)
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

function getusertags(user)
	d = cypherQuery(c, "MATCH (u:User {name: \$user})--(tt:Tagging)--(t:Tag) RETURN t.name, count(t) as c ORDER BY c DESC",
		"user" => user)
	get(d, 1, [])
end


function synctags(user, pid, tags)
	d = cypherQuery(c,
		"MATCH (u:User {name: \$user})--(tt:Tagging)--(p:Paper {uuid: \$pid}),
		       (tt)--(t:Tag)
		RETURN t.name", "user" => user, "pid" => pid)
	dbtags = get(d, 1, [])

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

function editpaper(pid, title, year)
	cypherQuery(c, "MATCH (p:Paper {uuid: \$pid})
		SET p.title = \$title, p.year = \$year",
		:pid => pid, :title => title, :year => year)
end

function syncauthors(pid, authors)
	# get current author names
	d = cypherQuery(c, "MATCH (:Paper {uuid: \$pid})--(a:Author) RETURN a.name", "pid" => pid)
	dbauthors = get(d, 1, [])

	@show add    = setdiff(authors, dbauthors)
	@show remove = setdiff(dbauthors, authors)

	tx = transaction(c)
	tx("MATCH (p:Paper {uuid: \$pid}) 
		UNWIND \$names as name 
		MATCH (p)-[r]-(a:Author {name: name}) 
		DELETE r", 
		"pid" => pid, "names" => remove)
	tx("MATCH (p:Paper {uuid: \$pid})
		UNWIND \$names as name
		MERGE (p)<-[:wrote]-(a:Author {name: name})",
		"pid" => pid, "names" => add)
	commit(tx)
end



## Middleware

function MuxHeaders(app, req)
	res = app(req)
	@show typeof(res)
	@show req
	addHeader(res)
end

function MuxQuery(app, req)
	req[:query] = HttpCommon.parsequerystring(req[:query])
	jq = get(req[:query], "json", "{}")
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

	@app app = (Mux.defaults, MuxQuery,
		    page("/", req->getpapers() |> json |> addHeader),
		    page("/papers", 
				req->(@show req; api_search(req[:jq]) |> json |> addHeader)),
		    page("/paper/:id", req->(getpaper(req[:params][:id]) |> json |> addHeader)),
		    page("/usertags/:user", req->(getusertags(req[:params][:user]) |> json |> addHeader)),
		    page("/editpaper", req->editpaper(req)|>json|>addHeader),
		    Mux.notfound())

	function api_search(d::Dict)
		api_search(d["query"], d["user"], d["usertags"])
	end

function editpaper(req)
	if length(req[:data]) > 0
		s = String(req[:data])
		d = JSON.parse(s)
		editpaper(d["pid"], d["title"], d["year"])
		syncauthors(d["pid"], d["authors"])
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
