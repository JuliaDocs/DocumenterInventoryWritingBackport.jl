# Source this script as e.g.
#
#     include("PATH/TO/devrepl.jl")
#
# from *any* Julia REPL or run it as e.g.
#
#     julia -i --banner=no PATH/TO/devrepl.jl
#
# from anywhere. This will change the current working directory and
# activate/initialize the correct Julia environment for you.
#
# You may also run this in vscode to initialize a development REPL
#
using Pkg
Pkg.activate(joinpath(@__DIR__, "test"))

function _instantiate()
    Pkg.develop(path=".")
end

if !isfile(joinpath("test", "Manifest.toml"))
    _instantiate()
end

include(joinpath("test", "clean.jl"))

REPL_MESSAGE = """
*******************************************************************************
DEVELOPMENT REPL

* `help()` – Show this message
* `clean()` – Clean up build/doc/testing artifacts
* `distclean()` – Restore to a clean checkout state
* `include("test/runtests.jl")` – Run the tests
*******************************************************************************
"""

"""Show help"""
help() = println(REPL_MESSAGE)

if abspath(PROGRAM_FILE) == @__FILE__
    help()
end
