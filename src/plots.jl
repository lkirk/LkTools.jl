using CairoMakie

using CairoMakie: CairoGlyph
function __init__()
    # # Makie look and feel (latex fonts, reduce padding, scale size by .7
    # set_theme!(theme_latexfonts(), figure_padding=5, size=(600, 450) .* 0.70)
    # CairoMakie.activate!(type="svg", pdf_version="1.5")
    isdefined(Main, :SixelTerm) && println("Using Sixel Scaling")
    init_scaling_config(; scale = isdefined(Main, :SixelTerm) ? 0.7 : 1)
end

function init_scaling_config(;
    dpi = 96,
    size = (6.4, 4.8),
    figure_padding = 5,
    type = "svg",
    pdf_version = "1.5",
    theme = theme_latexfonts,
    fontsize = 11,
    scale = 1,
)
    # size is in inches
    pt = dpi / 72  # 1pt = 1px when dpi=72
    set_theme!(
        theme(),
        figure_padding = figure_padding,
        size = size .* (scale * dpi),
        fontsize = fontsize * pt,
    )
    # set_theme!(theme(), figure_padding=figure_padding, size=size .* (scale * dpi), fontsize=fontsize * scale * pt)
    # visible = false so an image viewer does not pop up
    CairoMakie.activate!(
        type = type,
        pdf_version = pdf_version,
        px_per_unit = 1,
        visible = false,
    )
    # Disable png plots
    # push!(CairoMakie.DISABLED_MIMES, "image/png")
end

function plot_to_file(fig, filename; options...)
    mkpath(dirname(filename))
    save(filename, fig; options)
end

common_kwargs = """
- `hidex::Bool = false`: hide all but the bottom row of plots x-axis
  decorations.
- `hidey::Bool = false`: hide all but the leftmost row of plots y-axis
  decorations.
- `link::Bool = false`: link all axes in grid.
- `linky::Bool = false`: y axes in grid.
- `linkx::Bool = false`: x axes in grid.
- `square::Bool = false`: create square plots (will resize to layout before
  returning).
- `rowgap::Float64 = nothing`: gap between rows, default is Makie default.
- `colgap::Float64 = nothing`: gap between cols, default is Makie default.
"""

"""
    axmat(ncols, nplots, f; kwargs...)

Map the provided function to every element of a grid of axes on the provided
figure. The signature of `fn` must be `f(i::Int, ax::Makie.Axis)`, the return
value does not matter and is discarded. The `i` parameter indicates the index of
the plot and is typically used to index into a vector of results to be
plotted. `ax` is the axis in which the data will be plotted.

# kwargs
- `return_idx = false`: return index for axis matrix. indices count along rows.
$(common_kwargs)
"""
function axmat(
    ncols::Int,
    nplots::Int,
    f::Makie.Figure;
    return_idx::Bool = false,
    hide::Bool = false,
    hidex::Bool = false,
    hidey::Bool = false,
    link::Bool = false,
    linkx::Bool = false,
    linky::Bool = false,
    square::Bool = false,
    rowgap::Union{Float64,Nothing} = nothing,
    colgap::Union{Float64,Nothing} = nothing,
    ax_kwargs...,
)
    idx = permutedims(reshape(1:nplots, ncols, :))
    ax_kwargs = square ? (:aspect => AxisAspect(1), ax_kwargs...) : ax_kwargs
    axes = map(idx .- 1) do i
        Axis(f[i÷ncols+1, i%ncols+1]; ax_kwargs...)
    end
    (link || linkx) && linkxaxes!(axes...)
    (link || linky) && linkyaxes!(axes...)
    (hide || hidex) &&
        map(ax -> hidexdecorations!(ax; grid = false), axes[1:end-1, :])
    (hide || hidey) && map(ax -> hideydecorations!(ax; grid = false), axes[:, 2:end])
    square && map(i -> rowsize!(f.layout, i, Aspect(1, 1.0)), 1:size(axes, 1))
    !isnothing(rowgap) && rowgap!(f.layout, rowgap)
    !isnothing(colgap) && colgap!(f.layout, colgap)
    if size(axes) == (1, 1)
        return return_idx ? (idx, f, axes[1]) : (f, axes[1])
    end
    return_idx ? (idx, f, axes) : (f, axes)
end

"""
    axforeach(ncols, nplots, f, fn; kwargs...)

Map the provided function to every element of a grid of axes on the provided
figure. The signature of `fn` must be `f(i::Int, ax::Makie.Axis)`, the return
value does not matter and is discarded

# kwargs
$(common_kwargs)
"""
function axforeach(ncols::Int, nplots::Int, f::Makie.Figure, fn::Function; kwargs...)
    idx, f, axes = axmat(ncols, nplots, f; return_idx = true, kwargs...)
    map((i, ax) -> fn(i, ax), idx, axes)
    :square ∈ keys(kwargs) && kwargs[:square] && resize_to_layout!(f)
    (f, axes)
end

"""
    axfunc(ncols, nplots, f, fn; kwargs...)

Func the provided function to every element of a grid of axes on the provided
figure. The signature of `fn` must be `f(i::Int, ax::Makie.Axis)`, the return
value does not matter and is discarded

Pass the generated matrix of axes to the plotting function directly. The
signature of `fn` must be `f(f::Makie.Figure, axes::Matrix{Makie.Axis})`, where
`f` is the figure and `axes` is the matrix of axes. When mapping of this matrix
of axes, it helps to orient the data in the exact way it should be plotted
(matrix form). The return value of the plotting function does not matter and is
discarded.

# kwargs
$(common_kwargs)
"""
function axfunc(ncols::Int, nplots::Int, f::Makie.Figure, fn::Function; kwargs...)
    f, axes = axmat(ncols, nplots, f; kwargs...)
    fn(f, axes)
    :square ∈ keys(kwargs) && kwargs[:square] && resize_to_layout!(f)
    (f, axes)
end

"""
Update the properties of an axis in bulk
"""
function update_axis!(ax::Makie.Axis; kwargs...)
    for (k, v) in pairs(kwargs)
        setproperty!(ax, k, v)
    end
end

# meh... series?
# function multilines(f::Makie.Figure, x, y; label=nothing)
#     fig = Figure()
#     ax = Axis(fig[1, 1])
#     x = -10:.01:10
#     for Vs in [.01, 0.1, 1, 5, 10]
#         lines!(ax, x, z->exp(-z^2/Vs), label=L"V_S=%$Vs")
#     end
#     axislegend()
#     fig
# end
