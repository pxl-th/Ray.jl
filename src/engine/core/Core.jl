module EngineCore
export get_height, get_width, set_width, set_height

using Parameters: @with_kw
using GLFW
using ..Abstractions
using ..OpenGLBackend
using ..Event
using ..Ray

GLFW_INITIALIZED = false

include("window.jl")
include("layer.jl")
include("layer_stack.jl")
include("input.jl")

end
