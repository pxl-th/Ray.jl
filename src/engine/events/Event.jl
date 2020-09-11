module Event

abstract type AbstractEvent end

mutable struct WindowClose <: AbstractEvent
    handled::Bool
end

end
