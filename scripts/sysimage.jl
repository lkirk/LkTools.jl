using PackageCompiler
using Pkg

Pkg.activate(temp = true)
Pkg.add(["Pkg", "CSV", "CairoMakie", "DataFrames", "JSON"])

using CSV
using CairoMakie
using DataFrames
using JSON

create_sysimage(
    ["Pkg", "CSV", "CairoMakie", "DataFrames", "JSON"];
    sysimage_path = "LkTools.so",
)
