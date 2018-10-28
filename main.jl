using Neo4j
using JSON

global c

function connect!()
#	c = Connection("hobby-nnlcngdpepmbgbkedicfecbl.dbs.graphenedb.com"; port=24780, tls=true, user="root", password="b.tgZCossrIiMK.9PqYxW6BehPlQHls")
	global c = Connection("localhost"; user="neo4j", password="alex")
end

connect!()

clear!() = cypherQuery(c, "MATCH (n) DETACH DELETE n")

struct Paper
	year
	title
	authors
end

Base.show(io::IO, p::Paper) = dump(p)#("$(p.year) - $(reduce(*, p.authors)) - $(p.title)")

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

function addfile(filename)
	if endswith(filename, ".pdf")
		y, as, t = match(r"(\d+) - (.*?) - (.*).pdf", file).captures
		as = split(as, ' ')
		add(Paper(y,t,as), true)
	elseif endswith(filename, ".cermxml")
		string = open(filename) do f read(f, String) end
		pd = xp_parse(string)
		add(parsepaper(pd), parserefs(pd))
	end
end

function adddir(dirname=".")
	cd(dirname) do
		map(addfile, readdir())
	end
end

readdirxml() = filter(x->endswith(x, ".cermxml"), readdir())

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


using LibExpat
import LibExpat.find

function parserefs(pd)
	refs = find(pd, "//ref")
	ps = Paper[]
	for r in refs
		try
			names = xpath(r, xpath"mixed-citation/string-name/surname")
			as = map(x->x.elements[1], names)
			title = xpath(r, xpath"*/article-title")[1].elements[1]
			year = xpath(r, xpath"*/year")[1].elements[1]
			push!(ps, Paper(year, title, as))
		catch
			@warn "couldnt parse $r"
		end
	end
	ps
end

function parsepaper(pd)
	meta = xpath(pd, xpath"//article-meta")
	title = try xpath(meta, xpath"//article-meta//article-title")[1].elements[1]
		catch 
		"" end
	year  = try xpath(meta, xpath"//article-meta//year")[1].elements[1]
		catch 
		"" end
	as    = try map(x->x.elements[1], xpath(meta, xpath"//article-meta//contrib-group//string-name"))
	catch 
	[] end
	Paper(year, title, as)
end


include("server.jl")
