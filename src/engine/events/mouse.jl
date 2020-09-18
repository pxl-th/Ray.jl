abstract type MouseEvent <: AbstractEvent end
abstract type MouseButtonEvent <: MouseEvent end

mutable struct MouseMoved <: MouseEvent
    handled::Bool
    x::Float64
    y::Float64
end

mutable struct MouseScrolled <: MouseEvent
    handled::Bool
    x_offset::Float64
    y_offset::Float64
end

mutable struct MouseButtonPressed <: MouseButtonEvent
    handled::Bool
    button::MouseButton
end

mutable struct MouseButtonReleased <: MouseButtonEvent
    handled::Bool
    button::MouseButton
end
