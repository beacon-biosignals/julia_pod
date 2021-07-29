using Pkg

Pkg.add("PackageCompiler")

using PackageCompiler, UUIDs

function main()
    packages = [Symbol(k) for k in keys(Pkg.project().dependencies)]
    # exclude some packages that can make sysimage creation or usage fail.
    exclude = [:Revise, :PackageCompiler, :K8sClusterManagers]
    println("excluding $exclude")
    packages = setdiff(packages, exclude)
    println("Creating sys image with deps being tracked from a registry:")
    println(packages)
    create_sysimage(packages; sysimage_path="deps.so", cpu_target = "generic;sandybridge,-xsaveopt,clone_all;haswell,-rdrnd,base(1)")
    Pkg.rm("PackageCompiler")
end

main()
