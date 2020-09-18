module Renderer
export get_backend, set_backend

include("../../backend/Abstractions.jl")
include("../../backend/opengl/OpenGL.jl")

using .Abstractions
using .OpenGLBackend

let backend = OpenGLBackend
    global get_backend() = backend
    global set_backend(new_backend) = backend = new_backend
end

end
