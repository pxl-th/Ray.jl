module Input
export is_key_pressed, is_mouse_button_pressed, get_mouse_position

using GLFW
using ..Ray

"""
For now we rely only on GLFW for input polling.
"""
function is_key_pressed(key::GLFW.Key)::Bool
    native_window = Ray.get_application() |> Ray.native_window
    GLFW.GetKey(native_window, key)
end

function is_mouse_button_pressed(button::GLFW.MouseButton)::Bool
    native_window = Ray.get_application() |> Ray.native_window
    GLFW.GetMouseButton(native_window, button)
end

function get_mouse_position()::NamedTuple{(:x, :y), Tuple{Float64, Float64}}
    native_window = Ray.get_application() |> Ray.native_window
    GLFW.GetCursorPos(native_window)
end

get_mouse_x()::Float64 = get_mouse_position().x
get_mouse_y()::Float64 = get_mouse_position().y

end
