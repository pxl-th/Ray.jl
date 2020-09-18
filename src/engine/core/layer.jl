abstract type Layer end

function on_attach(::Layer) end
function on_detach(::Layer) end
function on_update(::Layer, timestep::Float64) end
function on_event(::Layer, ::Event.AbstractEvent) end

function on_imgui_begin(::Layer) end
function on_imgui_end(::Layer) end
function on_imgui_render(::Layer, timestep::Float64) end
