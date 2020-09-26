using PackageCompiler

create_sysimage(
    [:GeometryBasics, :Images, :ImageMagick, :StaticArrays, :Parameters],
    sysimage_path="sysimage.dll",
    precompile_execution_file="precompile.jl",
)
