"""
For now we rely only on GLFW for input polling.
"""
abstract type Input end

function is_key_pressed(::Input, key::GLFW.Key)::Bool

end

function is_mouse_button_pressed(::Input, button::GLFW.MouseButton)::Bool

end

function get_mouse_position(::Input)::Tuple{Float64, Float64}

end

function get_mouse_x(::Input)::Float64

end

function get_mouse_y(::Input)::Float64

end
