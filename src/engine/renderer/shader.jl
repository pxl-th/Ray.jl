struct ShaderLibrary
    shaders::Dict{String, Backend.Shader}
    ShaderLibrary() = new(Dict{String, Backend.Shader}())
end

add!(library::ShaderLibrary, shader::Backend.Shader) =
    library.shaders[shader.name] = shader

add!(library::ShaderLibrary, name::String, shader::Backend.Shader) =
    library.shaders[name] = shader

function load!(library::ShaderLibrary, name::String, path::String)
    shader = Backend.Shader(path)
    library.shaders[name] = shader
end

function load!(library::ShaderLibrary, path::String)
    shader = Backend.Shader(path)
    library.shaders[shader.name] = shader
end

function get(library::ShaderLibrary, name::String)
    library.shaders[name]
end

function exists(library::ShaderLibrary, name::String)::Bool
    name in keys(library.shaders)
end
