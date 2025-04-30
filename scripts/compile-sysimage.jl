using ArgParse: ArgParseSettings, add_arg_table, parse_args
using Logging
using PackageCompiler: create_sysimage
using Pkg: activate

function parseargs()
    s = ArgParseSettings()
    add_arg_table(s, ["--out", "-o"], Dict(:help => "sysimage out path"))
    add_arg_table(s, ["--out-dir", "-d"], Dict(:help => "sysimage out dir"))
    add_arg_table(
        s,
        ["--precomp-exec", "-p"],
        Dict(:help => "precompile execute file"),
        # TODO: can be list
    )
    add_arg_table(
        s,
        ["--exclude", "-x"],
        Dict(:help => "packages to exclude", :nargs => '+'),
    )
    add_arg_table(
        s,
        ["--soname", "-n"],
        Dict(:help => "base name of .so to generate (without version or .so suffix)"),
    )
    add_arg_table(
        s,
        ["--project"],
        Dict(:help => "dir of project to source when building", :default => "."),
    )
    # TODO should be list
    # add_arg_table(
    #     s,
    #     ["--extra-deps", "-e"],
    #     Dict(:help => "sysimage out dir", :nargs => '+'),
    # )
    return parse_args(ARGS, s)
end

function parse_so_version(fname::String, soname::String)
    m = match(r".*" * soname * r".(?<version>[0-9]+)\.so", fname)
    if !isnothing(m)
        return parse(Int64, m["version"])
    end
    error("Could not match so version in filename: '$fname'")
end

function next_so_version(outdir::String, soname::String)
    files = [p for p in readdir(outdir) if occursin(soname, p) && isfile(p)]
    length(files) == 0 && return 1
    maximum(map(fn -> parse_so_version(fn, soname), files)) + 1
end

function make_outdir(outdir::String)
    @info "Output .so file: $outdir"
    if !isdir(outdir)
        mkpath(outdir)
        @info "Created directory: $(dirname(outdir))"
    end
end

function get_dependencies(exclude, project)
    project_file = Base.env_project_file(project)
    typeof(project_file) != String &&
        error("Can't find project file. Are you in the package root?")
    [
        Symbol(k) for
        k in keys(Base.parsed_toml(project_file)["deps"]) if !(k in exclude)
    ]
end

function (@main)(_)
    args = parseargs()
    outfile = get(args, "out", nothing)
    outdir = get(args, "out-dir", nothing)
    if !isnothing(outfile) && !isnothing(outdir)
        error("--out-dir and --out are mutually exclusive")
    elseif isnothing(outfile)
        outdir = isnothing(outdir) ? expanduser("~/.julia/sysimage") : outdir
        make_outdir(outdir)
        soname = get(args, "soname", nothing)
        if isnothing(soname)
            error("if no outfile is given, an soname must be given")
        end
        outfile = joinpath(outdir, "$soname.$(next_so_version(outdir, soname)).so")
    else
        make_outdir(dirname(outfile))
    end
    @info "Output .so file: $outfile"
    deps = get_dependencies(get(args, "exclude", String[]), args["project"])
    # If script is run in another dir with JULIA_ENV, we don't want this to
    # propagate to 'create_sysimage', which runs a subprocess for the build.
    delete!(ENV, "JULIA_PROJECT")
    activate(args["project"])
    # But, in order to pick up the correct environment, we need to reset this.
    ENV["JULIA_PROJECT"] = args["project"]

    @info "Compiling with the following dependencies" deps
    create_sysimage(
        deps;
        sysimage_path = outfile,
        precompile_execution_file = get(args, "precomp-exec", String[]),
    )
    @info "Successfully created sysimage"
end
