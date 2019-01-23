function parsepdf(data::Vector{UInt8})
	dir = mktempdir()
		@show dir
		open("$dir/file.pdf", "w") do f
			write(f, data)
		end
		@show "written, now in $(pwd())"
		@show run(`java -cp cermine-impl-1.13-jar-with-dependencies.jar pl.edu.icm.cermine.ContentExtractor -path $dir -outputs jats`)
		addfile("$dir/file.cermxml")
	
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