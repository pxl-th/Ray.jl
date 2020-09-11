abstract type Layer end

function on_attach(::Layer) end
function on_detach(::Layer) end
function on_update(::Layer, ::Float64) end
function on_event(::Layer, ::Event.AbstractEvent) end
