using CSV

"""
Read a csv into a matrix. The CSV must represent a matrix of homogeneous
values. `kwargs` are passed directly to `CSV.read`.
"""
function csvmat(path; kwargs...)
    return CSV.read(path, CSV.Tables.matrix; header=false, kwargs...)
end
