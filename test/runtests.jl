using DocumenterInventoryWritingBackport
using DocInventories
using Test
TEST_PROJECT_PATH = joinpath(@__DIR__, "TestProject")
if LOAD_PATH[begin] != TEST_PROJECT_PATH
    pushfirst!(LOAD_PATH, TEST_PROJECT_PATH)
end
using Documenter: Documenter, makedocs
import TestProject


function run_makedocs(f, root; env=Dict{String,String}(), kwargs...)

    dir = mktempdir()

    cp(root, dir; force=true)

    default_format = Documenter.HTML()
    result = withenv(env...) do
        makedocs(;
            remotes=get(kwargs, :remotes, nothing),
            sitename=get(kwargs, :sitename, " "),
            format=get(kwargs, :format, default_format),
            root=dir,
            kwargs...
        )
    end

    f(dir)

end


function unescapeuri(str::AbstractString)
    unescaped_chars = Char[]
    i = 1
    while i <= length(str)
        c = str[i]
        if c == '%'
            hex = str[nextind(str, i):nextind(str, i, 3)-1]
            char_code = parse(UInt8, hex, base=16)
            push!(unescaped_chars, Char(char_code))
            i = nextind(str, i, 3)
        else
            push!(unescaped_chars, c)
            i = nextind(str, i)
        end
    end
    return String(unescaped_chars)
end


@testset "DocumenterInventoryWritingBackport.jl" begin

    run_makedocs(
        joinpath(@__DIR__, "TestProject", "docs");
        sitename="TestProject",
        format=Documenter.HTML(;
            prettyurls = false,
            canonical  = "https://juliadocs.github.io/DocumenterInterLinks.jl",
            edit_link  = "",
        ),
    ) do dir

        inventory_file = joinpath(dir, "build", "objects.inv")
        @test isfile(inventory_file)
        if isfile(inventory_file)
            inventory = Inventory(inventory_file)
            show(stdout, MIME("text/plain"), inventory)
            @test inventory.project == "TestProject"
            if !DocumenterInventoryWritingBackport.DISABLED
                @test inventory.version == "1.0.0-DEV"
            end
            @test !isnothing(inventory[":jl:constant:`TestProject.EARTH`"])
            @test !isnothing(inventory[":jl:type:`TestProject.World`"])
            @test !isnothing(
                inventory[":jl:method:`TestProject.hello_world-Tuple{TestProject.World}`"]
            )
            @test !isnothing(inventory[":jl:method:`TestProject.hello_world-Tuple{}`"])
            @test !isnothing(inventory[":std:doc:`index`"])
            @test !isnothing(inventory[":std:doc:`api`"])
            @test length(inventory(":label:")) == 3
            item = inventory[":jl:method:`TestProject.hello_world-Tuple{}`"]
            @test DocInventories.uri(item) == "api.html#TestProject.hello_world-Tuple%7B%7D"
            for item in inventory
                uri = DocInventories.uri(item)
                if contains(uri, "#")
                    page, anchor = split(uri, "#")
                    file = joinpath(dir, "build", page)
                    @test isfile(file)
                    if isfile(file)
                        html = read(file, String)
                        id_str = "id=\"$(unescapeuri(anchor))\""
                        if !contains(html, id_str)
                        end
                        @test contains(html, id_str)
                    end
                else
                    file = joinpath(dir, "build", uri)
                    @test isfile(file)
                end
            end
        end

    end
end
