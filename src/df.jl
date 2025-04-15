using DataFrames: combine, groupby, nrow

value_counts(df, col) = combine(groupby(df, col), nrow)
