module OpenGLBackend

using GLFW
using ModernGL
using ..Abstractions

include("../macros.jl")

include("context.jl")
include("buffer.jl")
include("shader.jl")

end
