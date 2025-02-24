using IJulia, ArgParse

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--name"
            help = "Name of Kernel"
            arg_type = String
            default = "Julia-ZSH"
    end
    return parse_args(s)
end

parsed_args = parse_commandline()
name = parsed_args["name"]

kernelpath = installkernel(name, env=Dict(ENV))
println("$(name) has been installed to: $(kernelpath)")
