using Pkg

const project = Pkg.project()

const modulefile = joinpath(dirname(project.path), "src", "$(project.name).jl")

if project.ispackage && !isfile(modulefile)
    @info "Project is a package, but has no src/\$JULIA_PROJECT.jl, creating an empty one."
    mkpath(dirname(modulefile))
    open(modulefile, "w") do io
        println(io, "module $(project.name)")
        println(io, "end")
    end
end

# Skip generating a system image when there are no dependencies,
# or all deps are stdlibs.
if isempty(project.dependencies) || values(project.dependencies) ⊆ keys(Pkg.Types.stdlibs())
    exit(0)
end

Pkg.add(name="PackageCompiler", version="1")

using PackageCompiler, UUIDs

function main()
    packages = [Symbol(k) for k in keys(project.dependencies)]
    # exclude some packages that can make sysimage creation or usage fail.
    exclude = [:PackageCompiler]
    println("excluding $exclude")
    packages = setdiff(packages, exclude)
    println("Creating sys image with deps being tracked from a registry:")
    println(packages)
    create_sysimage(packages; replace_default=true, cpu_target = "generic;sandybridge,-xsaveopt,clone_all;haswell,-rdrnd,base(1)")
    Pkg.instantiate()
end

main()
Pkg.rm("PackageCompiler")
