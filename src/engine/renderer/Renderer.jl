module Renderer
export get_backend, set_backend, BufferElement, BufferLayout, size, length,
    submit

include("../../backend/Abstractions.jl")
include("../../backend/opengl/OpenGL.jl")

using .Abstractions
using .OpenGLBackend

let backend = OpenGLBackend
    global get_backend() = backend
    global set_backend(new_backend) = backend = new_backend
end

function begin_scene() end
function end_scene() end

function submit(shader::Abstractions.Shader, va::Abstractions.VertexArray)
    shader |> get_backend().bind
    va |> get_backend().bind
    get_backend().draw_indexed(va)
end

end
