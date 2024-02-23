module DocumenterInventoryWritingBackport

import Documenter
using Documenter.Builder: DocumentPipeline
try
    using Documenter.HTMLWriter: HTML, HTMLContext, get_url, pretty_url, getpage, pagetitle
catch
    using Documenter.Writers.HTMLWriter:
        HTML, HTMLContext, get_url, pretty_url, getpage, pagetitle
end
try
    using Documenter.MDFlatten: mdflatten
catch
    using Documenter.Utilities.MDFlatten: mdflatten
end
try
    using Documenter: doccat
catch
    using Documenter.Utilities: doccat
end
try
    using Documenter: Document
catch
    using Documenter.Documents: Document
end
try
    using Documenter: Anchor, anchor as get_anchor
catch
    using Documenter.Anchors: Anchor, anchor as get_anchor
end
try
    using Documenter: NavNode
catch
    using Documenter.Documents: NavNode
end
import Documenter: Selectors
using CodecZlib
using TOML

DISABLED = false
try
    global DISABLED = isdefined(Documenter.HTMLWriter, :write_inventory)
catch
end


"""
Pipeline step to write the `objects.inv` inventory to the `build` directory.

This runs after `Documenter.Builder.RenderDocument` and only if `Documenter`
was set up for HTML output.
"""
abstract type WriteInventory <: DocumentPipeline end

Selectors.order(::Type{WriteInventory}) = 6.1  # after RenderDocument

function Selectors.matcher(::Type{WriteInventory}, doc::Document)
    return any(fmt -> (fmt isa HTML), doc.user.format)
end

function Selectors.runner(::Type{WriteInventory}, doc::Document)
    if DISABLED
        @debug "Skip writing inventories in DocumenterInventoryWritingBackport: handled by Documenter"
    else
        write_inventory(doc)
    end
end


function write_inventory(doc::Document)

    i_html = findfirst(fmt -> (fmt isa HTML), doc.user.format)
    if isnothing(i_html)
        @debug "Skip writing $(repr(filename)): No HTML output"
        return
    end
    ctx = HTMLContext(doc, doc.user.format[i_html])

    @info "Writing inventory file."
    project = doc.user.sitename
    version = find_project_version()

    io_inv_header = open(joinpath(doc.user.build, "objects.inv"), "w")

    write(io_inv_header, "# Sphinx inventory version 2\n")
    write(io_inv_header, "# Project: $project\n")
    write(io_inv_header, "# Version: $version\n")
    write(io_inv_header, "# The remainder of this file is compressed using zlib.\n")
    io_inv = ZlibCompressorStream(io_inv_header)

    domain = "std"
    role = "doc"
    priority = -1
    for navnode in doc.internal.navlist
        name = replace(splitext(navnode.page)[1], "\\" => "/")
        uri = _get_inventory_uri(doc, ctx, navnode)
        dispname = _get_inventory_dispname(doc, ctx, navnode)
        line = "$name $domain:$role $priority $uri $dispname\n"
        write(io_inv, line)
    end

    domain = "std"
    role = "label"
    priority = -1
    for name in keys(doc.internal.headers.map)
        isempty(name) && continue  # skip empty heading
        anchor = get_anchor(doc.internal.headers, name)
        if isnothing(anchor)
            # anchor not unique -> exclude from inventory
            continue
        end
        uri = _get_inventory_uri(doc, ctx, name, anchor)
        dispname = _get_inventory_dispname(doc, ctx, name, anchor)
        line = "$name $domain:$role $priority $uri $dispname\n"
        write(io_inv, line)
    end

    domain = "jl"
    priority = 1
    for name in keys(doc.internal.docs.map)
        anchor = get_anchor(doc.internal.docs, name)
        if isnothing(anchor)
            # anchor not unique -> exclude from inventory
            continue
        end
        uri = _get_inventory_uri(doc, ctx, name, anchor)
        role = lowercase(doccat(anchor.object))
        dispname = "-"
        line = "$name $domain:$role $priority $uri $dispname\n"
        write(io_inv, line)
    end

    close(io_inv)
    close(io_inv_header)

end


"""Find the project version number as a string.

```julia
version = find_project_version(pwd())
```

tries to extract a version from any `Project.toml`, `JuliaProject.toml`, or
`VERSION` file in the given folder or any parent folder.
"""
function find_project_version(dir=pwd())
    current_dir = dir
    parent_dir = dirname(current_dir)
    while parent_dir != current_dir
        for filename in ["Project.toml", "JuliaProject.toml"]
            project_toml = joinpath(current_dir, filename)
            if isfile(project_toml)
                project_data = TOML.parsefile(project_toml)
                if haskey(project_data, "version")
                    version = project_data["version"]
                    @debug "Obtained `version=$(repr(version))` for inventory from $(project_toml)"
                    return version
                end
            end
        end
        version_file = joinpath(current_dir, "VERSION")
        if isfile(version_file)
            version = strip(read(version_file, String))
            @debug "Obtained `version=$(repr(version))` for inventory from $(version_file)"
            return version
        end
        current_dir = parent_dir
        parent_dir = dirname(current_dir)
    end
    @warn "Cannot extract version for inventory from Project.toml"
    return ""
end


# URI for :std:label
function _get_inventory_uri(doc, ctx, name::AbstractString, anchor::Anchor)
    filename = relpath(anchor.file, doc.user.build)
    page_url = pretty_url(ctx, get_url(ctx, filename))
    if Sys.iswindows()
        # https://github.com/JuliaDocs/Documenter.jl/issues/2387
        page_url = replace(page_url, "\\" => "/")
    end
    page_url = join(map(_escapeuri, split(page_url, "/")), "/")
    label = ""
    try
        label = _escapeuri(Documenter.anchor_label(anchor))
    catch
        label = _escapeuri(Documenter.Anchors.fragment(anchor)[2:end])
    end
    if label == name
        uri = page_url * raw"#$"
    else
        uri = page_url * "#$label"
    end
    return uri
end


# URI for :std:doc
function _get_inventory_uri(doc, ctx, navnode::NavNode)
    uri = pretty_url(ctx, get_url(ctx, navnode.page))
    if Sys.iswindows()
        # https://github.com/JuliaDocs/Documenter.jl/issues/2387
        uri = replace(uri, "\\" => "/")
    end
    uri = join(map(_escapeuri, split(uri, "/")), "/")
    return uri
end


# dispname for :std:label
function _get_inventory_dispname(doc, ctx, name::AbstractString, anchor::Anchor)
    dispname = name
    try
        dispname = mdflatten(anchor.node)
    catch
        # We don't really care about the `dispname`
    end
    if dispname == name
        dispname = "-"
    end
    return dispname
end


# dispname for :std:doc
function _get_inventory_dispname(doc, ctx, navnode::NavNode)
    dispname = navnode.title_override
    if isnothing(dispname)
        page = getpage(ctx, navnode)
        title_node = nothing
        try
            title_node = pagetitle(page.mdast)
        catch
            title_node = pagetitle(page)
        end
        if isnothing(title_node)
            dispname = "-"
        else
            dispname = mdflatten(title_node)
        end
    end
    return dispname
end


@inline _issafe(c::Char) =
    c == '-' || c == '.' || c == '_' || (isascii(c) && (isletter(c) || isnumeric(c)))

_utf8_chars(str::AbstractString) = (Char(c) for c in codeunits(str))

_escapeuri(c::Char) = string('%', uppercase(string(Int(c), base=16, pad=2)))
_escapeuri(str::AbstractString) =
    join(_issafe(c) ? c : _escapeuri(c) for c in _utf8_chars(str))

end
