module Ray

using Parameters: @with_kw
using ModernGL

include("backend/Abstractions.jl")
include("backend/opengl/OpenGL.jl")

include("engine/events/Event.jl")
include("engine/core/Core.jl")
include("engine/imgui/ImGUI.jl")

using .Event
using .EngineCore
using .ImGUI

@with_kw mutable struct Application
    window::EngineCore.Window
    layer_stack::EngineCore.LayerStack = EngineCore.LayerStack()

    running::Bool = true
    minimized::Bool = false
    last_frame_time::Float64 = 0.0
end

function Application(name::String = "Ray")
    props = EngineCore.WindowProps(title=name)
    window = EngineCore.Window(props)
    app = Application(window=window)

    EngineCore.set_callbacks(window, (on_event, app))

    app
end

native_window(app::Application) = app.window.window

close(app::Application) = app.running = false

function on_event(app::Application, event::Event.WindowClose)
    app.running = false
    event.handled = true
    EngineCore.on_event(app.layer_stack, event)
    event
end

function on_event(app::Application, event::Event.WindowResize)
    @info "New resolution $(event.width)x$(event.height)"
    EngineCore.on_event(app.layer_stack, event)
    event
end

function run(app::Application)
    while app.running
        current_time = time()
        timestep = app.last_frame_time > 0.0 ?
            (current_time - app.last_frame_time) : (1 / 60)
        app.last_frame_time = current_time

        glClearColor(1, 0, 0, 1)
        glClear(GL_COLOR_BUFFER_BIT)

        !app.minimized && (
            ImGUI.on_begin();
            EngineCore.on_update(app.layer_stack, timestep);
            ImGUI.on_end();
        )
        app.window |> EngineCore.on_update
    end
end

function main()
    application = Application()
    EngineCore.push_overlay(
        application.layer_stack, ImGUI.ImGuiLayer(), native_window(application))
    application |> run
end
main()

end
