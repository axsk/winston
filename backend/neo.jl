using Neo4j
using JSON

function connect()
	return Connection("localhost"; user="neo4j", password="alex")
end

c = connect()

function query(q, args...)
	tx = transaction(c)
	tx(q, args...)
	global r = commit(tx)
	map(r.results[1]["data"]) do row
		row["row"]
	end
end

### ATOMIC GETS

function getPapers(ids::Vector{<:AbstractString})
	d = query(raw"
	UNWIND $ids as id
	MATCH (p:Paper {uuid:id}), (u:User {name: $user})
	OPTIONAL MATCH 
		(p)--(a:Author)
	OPTIONAL MATCH
		(p)--(tt:Tagging)--(u), (tt)--(t:Tag)
	OPTIONAL MATCH
		(p)--(x)--(u) WHERE x:Tagging OR x:Highlight OR x:Comment 
	OPTIONAL MATCH
		(p)--(f:File)
	RETURN min(x.created), max(x.created), p, collect(distinct t.name), collect(distinct a), count(f)",
	:ids => ids, :user => "Alex")
	map(d) do res
		#return res
		t = Paper(res[3], usertags = res[4], authors = res[5], editfirst=res[1], editlast=res[2])
		#Dict("authors" => res[5])
		t = typedictsparse(t)
		t[:files]=res[6]
		t
		#Dict(tmin=>res[1], )
	end
end

loaduuid(uuid::String) = getPapers([uuid])[1]

function loadrefs(uuid)::Vector{Paper}
	d = query(raw"
	MATCH (p:Paper {uuid:$uid})-[:referenced]->(r:Paper)--(a:Author)
	OPTIONAL MATCH (r)--(tt:Tagging)--(u:User {name: $user}), (tt)--(t:Tag) 
	RETURN r, collect(t.name) as tags, collect(a) as a", :uid => uuid, :user => "Alex")
	@show d
	map(d) do res
		Paper(res[1], usertags = res[2], authors = res[3])
	end
end

function getauthor(id)
	d = query(raw"
		MATCH (a:Author {uuid:$id}) 
		OPTIONAL MATCH (a)--(p:Paper)
		RETURN a, collect(p.uuid)", 
		:id => id)
	Dict(d[1][1]..., "papers" => getPapers(Vector{String}(d[1][2])))
end


### SEARCH

#=function getpapers(user="Alex")
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
	 end=#

# get first and last modification (comment, highlight, tag) for specified paper and user
function edittimes(p::Paper)
	d = cypherQuery(c, raw"
		MATCH (p:Paper {uuid: $id})--(x)--(u:User {name: 'Alex'}) 
		WHERE x:Tagging OR x:Highlight OR x:Comment WITH x.created AS t ORDER BY t
		RETURN apoc.agg.first(t), apoc.agg.last(t)",
		:id => p.uuid)
	try 
		return Paper(p, editfirst=d[1,1], editlast=d[1,2])
	catch
		return p
	end
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
		p = Paper(r[1], authors=r[2], usertags=r[3])
		p = edittimes(p)
	end

	if length(results) < 1 && usertags == []
		WebCrawl.Crossref.search(query=query, limit=20)
	else
		results
	end
end

### PDF
using Base64

function savepdf(pid, data::Vector{UInt8})
	d = cypherQuery(c, "
		MATCH (p:Paper {uuid: \$pid}) 
		CREATE (f:File {data: \$data, 
					   created: datetime(),
					   uuid: apoc.create.uuid()}),
			(p)-[:has]->(f)
		RETURN f.uuid",
		:pid => pid, :data => data)
	return (size(d,1) == 1)
end

#=
function savepdf(pid, data::Vector{UInt8})
	if pid == 0
		mktempdir() do dir
			open("$dir/file.pdf", "w") do f
				write(f, data)
			end
			run(`java -cp cermine-impl-1.13-jar-with-dependencies.jar pl.edu.icm.cermine.ContentExtractor -path $dir -outputs jats`)
			Cermine.addfile("$dir/file.cermxml")
		end
	end
end
=#

function loadpdf(uuid)
	d = cypherQuery(c, "MATCH (f:File)<-[:has]-(p:Paper {uuid: \$uuid}) RETURN f.data", :uuid => uuid)
	try 
		Vector{UInt8}(d[1][1])
	catch
		UInt8[]
	end
end

### COMMENTS

function addcomment(pid, user, text)
	d = cypherQuery(c, "
		MATCH (p:Paper: {uuid: \$pid}), (u:User {name: \$user})
		CREATE (u)-[:wrote]->(c:Comment {text: \$text, created: datetime()})-[:on]->(p)
		RETURN c",
		:pid => pid, :user => user, :text => text)
	return (size(d,1) == 1)
end

function getcomments(pid)
	d = cypherQuery(c, 
		"MATCH (p:Paper {uuid: \$pid})--(c:Comment) RETURN c",
		:pid => pid)
	return d[1]
end

function puthighlight(pid, user, highlight)
	d = cypherQuery(c,
		"MATCH (p:Paper {uuid: \$pid}), (u:User {name: \$user})
		MERGE (u)-[:selects]->(h:Highlight {location: \$loc})-[:selects]->(p)
		ON CREATE SET
		h.uuid = apoc.create.uuid(),
		h.created = datetime(),
		h.text = \$text
		RETURN h",
		:pid => pid, :user => user, :loc => highlight["location"], :text => highlight["text"])[1]
end

function putnote(pid, user, note)
	d = cypherQuery(c,
		"MATCH (p:Paper {uuid: \$pid}), (u:User {name: \$user})
		MERGE (u)-[:wrote]->(c:Comment {location: \$loc})-[:on]->(p)
		ON CREATE SET
		c.uuid = apoc.create.uuid(),
		c.created = datetime()
		SET c.text = \$text
		RETURN c",
		:pid => pid, :user => user, :loc => note["location"], :text => note["text"])[1]
end

function gethighlights(pid, user)
	d = cypherQuery(c,
		"MATCH (p:Paper {uuid: \$pid})--(h:Highlight)--(u:User {name: \$user}) RETURN h",
		:pid => pid, :user => user)
	get(d, 1, [])
end

function getcomments(pid, user)
	d = cypherQuery(c,
		"MATCH (p:Paper {uuid: \$pid})--(c:Comment)--(u:User {name: \$user}) RETURN c",
		:pid => pid, :user => user)
	get(d, 1, [])
end

test_api_search() = api_search("", "Alex", ["Library"])
#test_api_search()

function getusertags(user)
	d = cypherQuery(c, "MATCH (u:User {name: \$user})--(tt:Tagging)--(t:Tag) RETURN t.name, count(t) as c ORDER BY c DESC",
		"user" => user)
	get(d, 1, [])
end

function authorpapers(author::Author)::Vector{Paper}
	d = cypherQuery(c,
		"MATCH (p:Paper)-(a:Author {uuid: \$aid}) RETURN p",
		:aid => author.uuid)
	map(Paper, d[1])
end

# UPDATES

function syncpaper(p::Paper, user)
	if isa(p.uuid, Int) || isnothing(p.uuid)
		@show "creating new paper", p
		pid = create(p).uuid
	else
		pid = update(p).uuid
	end
	#pid = p.uuid == nothing ? create(p).uuid : update(p).uuid
	syncauthors(pid, p.authors)
	synctags(pid, p.usertags, user)
	#TODO: syncrefs, synccits
	return pid
end

function syncauthors(pid, authors::Vector{Author})
	authors == nothing && return

	aids = map(authors) do a
		a.uuid == nothing ? create(a).uuid : update(a).uuid
	end

	tx = transaction(c)
	tx("MATCH (p:Paper {uuid: \$pid})-[r]-(:Author) DELETE r",
		:pid => pid)
	tx("MATCH (p:Paper {uuid: \$pid}) WITH p
		UNWIND range(1, size(\$aids)) AS i
		MATCH (a:Author {uuid: \$aids[i-1]})
		CREATE (a)-[:wrote {position: i}]->(p)",
		:pid => pid, :aids => aids)
	e = commit(tx).errors
	length(e) > 0 && throw(e)
	true
end

function synctags(pid, tags, user)
	tags == nothing && return

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
		CREATE (u)-[:tag]->(tt:Tagging {created: datetime()})-[:tag]->(p),
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
	e = commit(tx).errors
	length(e) > 0 && throw(e)
	true
end

function syncreferences(p::Paper)
	p.references == nothing && return
	# we probably dont need the update below
	ids = map(p.references) do x
		x.uuid == nothing ? create(x).uuid : update(x).uuid
	end
	cypherQuery(c, 
		"MATCH (p:Paper {uuid: \$pid})
		UNWIND \$ids as id
		MERGE (:Paper {uuid: id})<-[:referenced]-(p)",
		:pid => p.uuid, :ids => ids)
end

function synccitations(p::Paper)
	p.citations == nothing && return
	# we probably dont need the update below
	ids = map(p.citations) do x
		x.uuid == nothing ? create(x).uuid : update(x).uuid
	end
	cypherQuery(c, 
		"MATCH (p:Paper {uuid: \$pid})
		UNWIND \$ids as id
		MERGE (:Paper {uuid: id})-[:referenced]->(p)",
		:pid => p.uuid, :ids => ids)
end
	
# object mappers, also giving merge



function create(n::Node)
	d = cypherQuery(c,
		"CREATE (n$(label(n))) SET n+=\$n,
		n.uuid = apoc.create.uuid(),
		n.created = datetime() RETURN n",
		:n => node(n))
	convert(typeof(n), d[1,1])
end

# note that += doesnt remove properties
function update(n::Node)
	@show "updating $n"
	d = cypherQuery(c,
		"MATCH (n$(label(n)) {uuid: \$n.uuid}) SET n+=\$n RETURN n",
		:n => node(n))
	convert(typeof(n), d[1,1])
end

function mergenodes(master::Node, slave::Node)
	d = cypherQuery(c,
		"MATCH (m$(label(master)) {uuid: \$id1)}),
		       (s$(label(slave))  {uuid: \$id2)})
		CALL apoc.refactor.mergeNodes([m,s], {properties:'discard', mergeRels:true}) YIELD n",
		:id1 => master.uuid, :id2 => slave.uuid)
	convert(typeof(n), d[1,1])
end

function delete(n::Node)
	cypherQuery(c,
		"MATCH (n$(label(n)) {uuid: \$id})) DETACH DELETE",
		:id => n.uuid)
	nothing
end

### LEGACY GETS
#=
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

	add    = setdiff(authors, dbauthors)
	remove = setdiff(dbauthors, authors)

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
	    CREATE (u)-[:tag]->(tt:Tagging {created: datetime()})-[:tag]->(p),
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

#clear!() = cypherQuery(c, "MATCH (n) DETACH DELETE n")


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
=#