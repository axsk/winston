using Neo4j
using JSON

function connect()
	return Connection("localhost"; user="neo4j", password="alex")
end

c = connect()

### ATOMIC GETS

function loaduuid(uuid::String)::Paper
	d = cypherQuery(c,"MATCH (p:Paper {uuid:\$uid})--(a:Author) return p, collect(a) as a", :uid => uuid)
	Paper(d[1,1], authors = d[1,2])
end

function loadrefs(p::Paper)::Paper
	d = cypherQuery(c,"MATCH (p:Paper {uuid:\$uid})-[:referenced]->(r:Paper)--(a:Author) return r, collect(a) as a", :uid => p.uuid)
	refs = [Paper(d[i,1], authors = d[i,2]) for i in 1:size(d,1)]
	Paper(p, references = refs)
end

function test_atoms()
	uuid = "1"
	p = loaduuid(uuid)
	loadrefs(p)
end

### SEARCH

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

function api_search(query::String, user::String, usertags::Vector)
	query, user, usertags
	tx = transaction(c)
	tx( "MATCH (p:Paper)--(a:Author) with p, collect(a) as authors
		 OPTIONAL MATCH (p)--(tt:Tagging)--(u:User {name: \$user}),
		 	(tt)--(t:Tag)
		 WITH p, authors, collect(t.name) as tags
		 WHERE ALL(tag in \$usertags WHERE tag in tags)
		 AND p.title =~ \$regex
		 RETURN p, authors, tags
		 LIMIT 100",

		"regex" => "(?i).*" * query * ".*",
		"user" => user,
		"usertags" => usertags)
	r = commit(tx)
	results = map(r.results[1]["data"]) do r
		r = r["row"]
		#p = parsepaperauthor(r[1],r[2])
		p = Paper(r[1], authors=r[2], usertags=r[3])
		#p = Paper(p, usertags = r[3])
	end

	if length(results) < 1 && usertags == []
		WebCrawl.Crossref.search(query=query, limit=20)
	else
		results
	end
end

test_api_search() = api_search("", "Alex", ["Library"])
test_api_search()

# UPDATES

hasval(::Missing) = false
hasval(::Nothing) = false
hasval(::Any) = true

function syncpaper(p::Paper, user)
	editpaper(p)
	syncauthors(p)
	synctags(p, user)
end

function editpaper(p::Paper)
	tx = transaction(c)
	tx("MERGE (p:Paper {uuid: \$p.uuid})
		ON CREATE SET p.uuid = apoc.create.uuid(), p.date = datetime() " *
		(hasval(p.title) ? "SET p.title = \$p.title " : "") *
		(hasval(p.year)  ? "SET p.year = \$p.year " : "") *
		"RETURN p",
		:p => p)
	r = commit(tx)
	
	Paper(r.results[1]["data"][1]["row"][1])
end

function syncauthors(p::Paper)
	pid = p.uuid
	d = cypherQuery(c, "MATCH (:Paper {uuid: \$pid})--(a:Author) RETURN a", :pid => pid)

	dbauthors = map(Author, get(d, 1, []))
	@show add    = setdiff(p.authors, dbauthors)
	@show remove = setdiff(dbauthors, p.authors)
	
	tx = transaction(c)
	# TODO: not working with old style authors; FIX: use uuid
	tx("MATCH (p:Paper {uuid: \$pid})
		UNWIND \$authors as a
		MATCH (p)-[r]-(:Author {given: a.given, family: a.family})
		DELETE r",
		:pid => pid, :authors => remove)
	tx("MATCH (p:Paper {uuid: \$pid})
		UNWIND \$authors as a
		MERGE (p)<-[:wrote]-(:Author {given: a.given, family: a.family})",
		:pid => pid, :authors => add)
	commit(tx)
end

function synctags(paper, user)
	pid = paper.uuid
	tags = paper.usertags

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

### LEGACY GETS

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

### LEGACY WRITES

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

### LEGACY ###

clear!() = cypherQuery(c, "MATCH (n) DETACH DELETE n")


function add(p::Paper, owned=false)
	owned = owned ? ":Owned" : ""
	tx = transaction(c)
	tx(
	   "MERGE (p:Paper$owned {year: \$year, title:\$title})
	   ON CREATE SET p.uuid = apoc.create.uuid(), p.date = datetime()
	   WITH p FOREACH (i IN range(1, size(\$auths)) |
	   MERGE (a:Author {name: \$auths[i-1]})
	   MERGE (a)-[:wrote {position: i}]->(p))"
	   , "year" => p.year, "title" => p.title, "auths" => p.authors)
	results=commit(tx)
	return tx
end

function addref(f::Paper, t::Paper)
	tx = transaction(c)
	tx(
	   "MATCH (f:Paper {year: \$fyear, title:\$ftitle})
	    MATCH (t:Paper {year: \$tyear, title:\$ttitle})
	    MERGE (f)-[:referenced]->(t)
	    RETURN t",
	    "fyear" => f.year, "ftitle" => f.title,
	    "tyear" => t.year, "ttitle" => t.title)
	commit(tx)
end

function add(p::Paper, rs::Vector{Paper})
	add(p, true)
	for r in rs
		add(r)
		addref(p, r)
	end
end

function adduser(username)
	tx = transaction(c)
	tx("CREATE (u:User {name: \$name})", "name" => username)
	commit(tx)
end

function addtag(user::String, p::Paper, tag::String)
	tx = transaction(c)
	tx("MATCH (u:User {name: \$user}),
	   	  (p:Paper {year: \$year, title: \$title})
	    MERGE (t:Tag  {name: \$tag})
	    CREATE (u)-[:tag]->(tt:Tagging)-[:tag]->(p), (tt)-[:tag]->(t)
	    SET tt.date = datetime()",
	    "user" => user, "year" => p.year, "title" => p.title, "tag" => tag)
	commit(tx)
end