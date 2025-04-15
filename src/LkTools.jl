module LkTools

using CairoMakie
using CSV

include("csv.jl")
include("plots.jl")
include("df.jl")

# Export CSV in case we need its symbols for kwargs
# csv.jl
export CSV

# plots.jl
export axmat,
    axforeach, axfunc, csvmat, init_scaling_config, plot_to_file, update_axis!

# df.jl
export value_counts

function re_export(mod)
    for name in Base.names(mod, all = true)
        if Base.isexported(mod, name)
            @eval export $(name)
        end
    end
end

# Re-export CairoMakie along with our plotting code, for convenience.
re_export(CairoMakie)

end # module LkTools
