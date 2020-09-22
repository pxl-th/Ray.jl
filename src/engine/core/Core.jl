module EngineCore
export
    Window, get_height, get_width, set_width, set_height, set_vsync, is_vsync,
    Layer, on_attach, on_detach, on_update, on_event,
    on_imgui_begin, on_imgui_end, on_imgui_render,
    LayerStack, pop_layer, pop_overlay, push_layer, push_overlay,
    is_key_pressed, is_mouse_button_pressed, get_mouse_position

using Parameters: @with_kw
using GLFW
using ..Renderer
using ..Event
using ..Ray

GLFW_INITIALIZED = false

include("window.jl")
include("layer.jl")
include("layer_stack.jl")
# include("input.jl")

end
