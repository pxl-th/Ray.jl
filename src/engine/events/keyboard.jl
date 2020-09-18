abstract type KeyEvent <: AbstractEvent end

mutable struct KeyPressed <: KeyEvent
    handled::Bool
    key::Key
    repeat::Int16
end

mutable struct KeyReleased <: KeyEvent
    handled::Bool
    key::Key
end

mutable struct KeyTyped <: KeyEvent
    handled::Bool
    key::Char
end
