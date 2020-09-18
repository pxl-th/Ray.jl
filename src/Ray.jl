module Ray

using GLFW

let application = nothing
    global get_application() = application
    global function set_application(app)
        application ≢ nothing &&
            error("Only one application instance is allowed.")
        application = app
    end
end

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
    set_application(app)

    EngineCore.set_callbacks(window, on_event)

    app
end

native_window(app::Application) = app.window.window

close(app::Application) = app.running = false

function on_event(app::Application, event::Event.WindowClose)
    app.running = false
    event.handled = true
    EngineCore.on_event(app.layer_stack, event)
end

function on_event(app::Application, event::Event.WindowResize)
    set_width(app.window, event.width)
    set_height(app.window, event.height)
    @info "Window resized [$(event.width)x$(event.height)]"
    EngineCore.on_event(app.layer_stack, event)
end

function on_event(app::Application, event::Event.KeyPressed)
    @info "Pressed [$(event.key)] key"
    EngineCore.on_event(app.layer_stack, event)
end

function on_event(app::Application, event::Event.KeyReleased)
    @info "Released [$(event.key)] key"
    EngineCore.on_event(app.layer_stack, event)
end

function on_event(app::Application, event::Event.AbstractEvent)
    @info "Default event fallback: $event"
    EngineCore.on_event(app.layer_stack, event)
end

function run(app::Application)
    while app.running
        current_time = time()
        timestep = app.last_frame_time > 0.0 ?
            (current_time - app.last_frame_time) : (1 / 60)
        app.last_frame_time = current_time

        glClearColor(0.9, 0.1, 0.1, 1)
        glClear(GL_COLOR_BUFFER_BIT)

        !app.minimized && begin
            EngineCore.on_update(app.layer_stack, timestep)
            EngineCore.on_imgui_render(app.layer_stack, timestep)
        end
        app.window |> EngineCore.on_update
    end
end

function main()
    application = Application()
    EngineCore.push_overlay(application.layer_stack, ImGUI.ImGuiLayer())
    application |> run
end
main()

end
