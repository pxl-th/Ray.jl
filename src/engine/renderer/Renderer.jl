module Renderer

include("../../backend/Abstractions.jl")
include("../../backend/opengl/OpenGL.jl")

using .Abstractions
using .OpenGLBackend

let backend = OpenGLBackend
    global get_backend() = backend
    global set_backend(new_backend) = backend = new_backend
end

export get_backend, set_backend, BufferElement, BufferLayout, size, length
end
