module Ray

using Parameters: @with_kw
using ModernGL

include("backend/Abstractions.jl")
include("backend/opengl/OpenGL.jl")

include("engine/events/Event.jl")
include("engine/renderer/Renderer.jl")

using .Event
using .Renderer

@with_kw mutable struct Application
    window::Renderer.Window
    layer_stack::Renderer.LayerStack = Renderer.LayerStack()

    running::Bool = true
    minimized::Bool = false
    last_frame_time::Float64 = 0.0
end

function Application(name::String = "Ray")
    props = Renderer.WindowProps(title=name)
    window = Renderer.Window(props)
    app = Application(window=window)

    Renderer.set_callbacks(window, (on_event, app))

    app
end

close(app::Application) = app.running = false

function on_event(app::Application, event::Event.WindowClose)
    app.running = false
    event.handled = true

    Renderer.on_event(app.layer_stack, event)
    event
end

function run(app::Application)
    while app.running
        current_time = time()
        timestep = current_time - app.last_frame_time
        app.last_frame_time = current_time

        !app.minimized && Renderer.on_update(app.layer_stack, timestep)

        glClearColor(1, 0, 0, 1)
        glClear(GL_COLOR_BUFFER_BIT)

        app.window |> Renderer.on_update
    end
end

function main()
    application = Application()
    application |> run
end
main()

end
