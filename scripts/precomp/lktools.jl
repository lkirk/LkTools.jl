using DataFrames
using CairoMakie

let
    df = DataFrame(:a => [1, 2, 3, 4, 5], :b => [2, 3, 4, 5, 6])

    scatter(rand(100))
    scatter(rand(100), rand(100))
    lines(rand(100))
    lines(rand(100), rand(100))
    hist(rand(100))

    fig = Figure()
    ax = Axis(fig[1, 1])
    scatter!(ax, rand(100))
    scatter!(ax, rand(100), rand(100))
    lines!(ax, rand(100))
    lines!(ax, rand(100), rand(100))
    hist!(ax, rand(100))
end
