import Pkg

@info "Checking if the IJulia package has been installed, and can be imported:"

# Check if package is already installed
isinstalled(pkg) = isnothing(Base.identify_package(pkg)) ? false :
                   haskey(Pkg.dependencies(), Base.identify_package(pkg).uuid)

# A broken manifest might trigger isinstalled to fail
try isinstalled("IJulia")
catch e
    @warn "Could not interrogate environment for IJulia:" e
    @info "Trying Pkg.resolve"
    Pkg.resolve()
    @info "Trying Pkg.instantiate"
    Pkg.instantiate()
end

# If IJulia is not installed, install it
if isinstalled("IJulia")
    @info "IJulia has been found in the active environment"
else
    @warn "IJulia has not been found in the active environment => installing"
    Pkg.add("IJulia")
end

# The environment might be fine, but the module is broken
try
    import IJulia
catch e
    @warn "Failed to import IJulia with error:" e
    @info "Updating IJulia (and any of its dependencies)"
    Pkg.update("IJulia"; preserve=Pkg.PRESERVE_NONE)
    @info "Trying Pkg.build(\"IJulia\")"
    # Prevent default kernel installation: https://julialang.github.io/IJulia.jl/stable/manual/installation/#Installing-additional-Julia-kernels
    ENV["IJULIA_NODEFAULTKERNEL"] = 1
    Pkg.build("IJulia")
finally
    import IJulia
end

@info "Success! IJulia found and seems to be working"
# Depending on the IJulia version, the kernel is launched either by running the
# kernel.jl file or the "run_kernel" function. This was bifurcated in v1.28:
# https://github.com/JuliaLang/IJulia.jl/blob/master/docs/src/_changelog.md#v1280---2025-06-01
#
# Last line of bootstrap.jl will be passed to Julia by the kernel-helper.sh
# (earlier lines will be ingored)
if pkgversion(IJulia) >= v"1.28"
    @info "New IJulia detected, using contemporary API" pkgversion(IJulia)
    println("-e 'import IJulia; IJulia.run_kernel()'")
else
    @info "Old IJulia detected, using legacy API" pkgversion(IJulia)
    println(joinpath(splitpath(pathof(IJulia))[1:end-1]..., "kernel.jl"))
end
