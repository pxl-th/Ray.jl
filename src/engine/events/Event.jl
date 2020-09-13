module Event

abstract type AbstractEvent end

mutable struct WindowClose <: AbstractEvent
    handled::Bool
end

mutable struct WindowResize <: AbstractEvent
    handled::Bool
    width::Int64
    height::Int64
end

end
