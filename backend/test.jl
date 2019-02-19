include("main.jl")
p=loaduuid("0eb6de89-05bb-47fb-8378-6a96adba99f9")
WebCrawl.crawl(p)

lib = api_search("", "Alex", ["Library"])
WebCrawl.crawl.(lib)

