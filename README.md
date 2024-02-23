# DocumenterInventoryWritingBackport.jl

[![Build Status](https://github.com/JuliaDocs/DocumenterInventoryWritingBackport.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/JuliaDocs/DocumenterInventoryWritingBackport.jl/actions/workflows/CI.yml?query=branch%3Amaster)

[`DocumenterInventoryWritingBackport.jl`](https://github.com/JuliaDocs/DocumenterInventoryWritingBackport.jl) is a backport the `Documenter v1.3` [feature of generating an `objects.inv` inventory file](https://github.com/JuliaDocs/Documenter.jl/pull/2424) to `Documenter v0.25`–`v1.2`.

See [Inventor Generation](http://juliadocs.org/DocumenterInterLinks.jl/stable/write_inventory/) for details.

## Installation

As usual, the package can be installed via

```
] add DocumenterInventoryWritingBackport
```

in the Julia REPL, or by adding

```
DocumenterInventoryWritingBackport = "195adf08-069f-4855-af3e-8933a2cdae94"
```

to the relevant `Project.toml` file.


## Usage

Add

```julia
using DocumenterInventoryWritingBackport
```

to a project's `docs/make.jl` file, or in the REPL where you are building the project's documentation. Then, build the documentation as normal.

Simply loading `DocumenterInventoryWritingBackport` in this way should be sufficient to ensure that an `objects.inv` inventory file will be created when building the documentation.
