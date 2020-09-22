struct ShaderLibrary
    shaders::Dict{String, get_backend().Shader}
    ShaderLibrary() = new(Dict{String, get_backend().Shader}())
end

add!(library::ShaderLibrary, shader::get_backend().Shader) =
    library.shaders[shader.name] = shader

add!(library::ShaderLibrary, name::String, shader::get_backend().Shader) =
    library.shaders[name] = shader

function load!(library::ShaderLibrary, name::String, path::String)
    shader = get_backend().Shader(path)
    library.shaders[name] = shader
end

function load!(library::ShaderLibrary, path::String)
    shader = get_backend().Shader(path)
    library.shaders[shader.name] = shader
end

function get(library::ShaderLibrary, name::String)
    library.shaders[name]
end

function exists(library::ShaderLibrary, name::String)::Bool
    name in keys(library.shaders)
end
