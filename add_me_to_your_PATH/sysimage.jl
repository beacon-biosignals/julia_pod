using Pkg, PackageCompiler, UUIDs

function main()
    project = Pkg.project()

    # Skip generating a system image when there are no dependencies, or all deps are stdlibs.
    if isempty(project.dependencies) || values(project.dependencies) ⊆ keys(Pkg.Types.stdlibs())
        exit(0)
    end

    packages = [Symbol(k) for k in keys(project.dependencies)]
    # exclude some packages that can make sysimage creation or usage fail.
    exclude = [:PackageCompiler]
    println("excluding $exclude")
    packages = setdiff(packages, exclude)
    println("Creating sys image with deps being tracked from a registry:")
    println(packages)
    create_sysimage(packages; replace_default=true, cpu_target = "generic;sandybridge,-xsaveopt,clone_all;haswell,-rdrnd,base(1)")
end

@time main()
