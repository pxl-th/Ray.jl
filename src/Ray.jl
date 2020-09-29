module Ray

using GeometryBasics
using GLFW
using Parameters: @with_kw
using ModernGL

let application = nothing
    global get_application() = application
    global function set_application(app)
        application ≢ nothing &&
            error("Only one application instance is allowed.")
        application = app
    end
end

include("backend/macros.jl")

include("engine/events/Event.jl")
include("engine/core/input.jl")
include("engine/core/Transformations.jl")

include("engine/renderer/OrthographicCamera.jl")
include("engine/renderer/Renderer.jl")
include("engine/renderer/Renderer2D.jl")

include("engine/core/Core.jl")
include("engine/imgui/ImGUI.jl")

using .Transformations
using .OrthographicCameraModule
using .Event
using .Input
using .Renderer
using .EngineCore
using .ImGUI

Backend = Renderer.get_backend()

mutable struct Application
    window::EngineCore.Window
    gui_layer::ImGuiLayer
    layer_stack::EngineCore.LayerStack

    running::Bool
    minimized::Bool
    last_frame_time::Float64
end

function Application(name::String = "Ray")
    props = EngineCore.WindowProps(title=name)
    window = EngineCore.Window(props)

    app = Application(
        window, ImGuiLayer(), EngineCore.LayerStack(), true, false, 0.0,
    )
    app |> set_application

    Backend.init()

    EngineCore.set_callbacks(window, on_event)
    push_overlay(app.layer_stack, app.gui_layer)

    app
end

native_window(app::Application) = app.window.window
close(app::Application) = app.running = false

function on_event(app::Application, event::Event.WindowClose)
    app.running = false
    event.handled = true
end

function on_event(app::Application, event::Event.KeyPressed)
    if event.key == GLFW.KEY_ESCAPE
        app.running = false
        event.handled = true
        return
    end
    EngineCore.on_event(app.layer_stack, event)
end

function on_event(app::Application, event::Event.WindowResize)
    if event.width == 0 || event.height == 0
        app.minimized = true
        return
    end

    app.minimized = false
    set_width(app.window, event.width)
    set_height(app.window, event.height)

    Backend.set_viewport(UInt32(event.width), UInt32(event.height))
    EngineCore.on_event(app.layer_stack, event)
end

on_event(app::Application, event::Event.AbstractEvent) =
    EngineCore.on_event(app.layer_stack, event)

function run(app::Application)
    while app.running
        current_time = time()
        timestep = app.last_frame_time > 0.0 ?
            (current_time - app.last_frame_time) : (1 / 60)
        app.last_frame_time = current_time

        if !app.minimized
            EngineCore.on_update(app.layer_stack, timestep)

            on_imgui_begin(app.gui_layer)
            EngineCore.on_imgui_render(app.layer_stack, timestep)
            on_imgui_end(app.gui_layer)
        end
        app.window |> EngineCore.on_update
    end
end

end
