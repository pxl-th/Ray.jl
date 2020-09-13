struct LayerStack
    layers::Vector{Layer}
    overlays::Vector{Layer}

    LayerStack() = new(Layer[], Layer[])
end

function push_layer(ls::LayerStack, layer::T) where T <: Layer
    push!(ls.layers, layer)
    on_attach(layer, args...)
end
function push_overlay(ls::LayerStack, layer::T, args...) where T <: Layer
    @info "Pushing overlay $(typeof(layer))"
    push!(ls.overlays, layer)
    on_attach(layer, args...)
end

function pop_layer(ls::LayerStack, layer::Layer)
    id = findfirst(x -> x == layer, ls.layers)
    id ≢ nothing && popat!(ls.layers, id, layer)
end
function pop_overlay(ls::LayerStack, layer::Layer)
    id = findfirst(x -> x == layer, ls.overlays)
    id ≢ nothing && popat!(ls.layers, id, layer)
end

function on_event(ls::LayerStack, event::T) where T <: Event.AbstractEvent
    for overlay in Iterators.reverse(ls.overlays)
        event.handled && return
        on_event(overlay, event)
    end
    for layer in Iterators.reverse(ls.layers)
        event.handled && return
        on_event(layer, event)
    end
end

function on_update(ls::LayerStack, timestep::Float64)
    for overlay in ls.overlays
        on_update(overlay, timestep)
    end
    for layer in ls.layers
        on_update(layer, timestep)
    end
end
