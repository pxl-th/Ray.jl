mutable struct MouseMovedEvent <: AbstractEvent
    x::Float64
    y::Float64
end

mutable struct MouseScrolledEvent <: AbstractEvent
    x_offset::Float64
    y_offset::Float64
end

abstract type AbstractMouseButtonEvent <: AbstractEvent end

mutable struct MouseButtonEvent <: AbstractMouseButtonEvent
    button::Codes.MouseCode
end

mutable struct MouseButtonPressedEvent <: AbstractMouseButtonEvent
    button::Codes.MouseCode
end

mutable struct MouseButtonReleasedEvent <: AbstractMouseButtonEvent
    button::Codes.MouseCode
end
