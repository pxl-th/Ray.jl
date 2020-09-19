module Ray

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
include("engine/renderer/Renderer.jl")
include("engine/events/Event.jl")
include("engine/core/Core.jl")
include("engine/imgui/ImGUI.jl")

using .Renderer
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

        glClearColor(0.1, 0.1, 0.1, 1)
        glClear(GL_COLOR_BUFFER_BIT)

        !app.minimized && begin
            EngineCore.on_update(app.layer_stack, timestep)
            EngineCore.on_imgui_render(app.layer_stack, timestep)
        end
        app.window |> EngineCore.on_update
    end
end

struct CustomLayer <: EngineCore.Layer
    vb::Renderer.get_backend().VertexBuffer
    ib::Renderer.get_backend().IndexBuffer
    va::UInt32
    shader::Renderer.get_backend().Shader
end

function CustomLayer()
    vertex_shader = raw"""
    #version 330 core

    layout (location = 0) in vec3 a_Position;

    void main() {
        gl_Position = vec4(a_Position, 1.0);
    }
    """
    fragment_shader = raw"""
    #version 330 core

    layout (location = 0) out vec4 color;

    void main() {
        color = vec4(0.8, 0.2, 0.3, 1.0);
    }
    """
    shader = Renderer.get_backend().Shader(vertex_shader, fragment_shader)

    triangle = Float32[
        -0.5, 0.0, 0.0,
         0.5, 0.0, 0.0,
         0.0, 0.5, 0.0,
    ]
    indices = UInt32[0, 1, 2]

    va = @ref glGenVertexArrays(1, RepUInt32)
    glBindVertexArray(va)

    vb = Renderer.get_backend().VertexBuffer(triangle, sizeof(triangle))
    vb |> Renderer.get_backend().bind

    ib = Renderer.get_backend().IndexBuffer(indices)
    ib |> Renderer.get_backend().bind

    glEnableVertexAttribArray(0)
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(Float32), C_NULL)

    CustomLayer(vb, ib, va, shader)
end

function EngineCore.on_update(cs::CustomLayer, timestep::Float64)
    cs.shader |> Renderer.get_backend().bind
    glBindVertexArray(cs.va)
    glDrawElements(GL_TRIANGLES, cs.ib.count, GL_UNSIGNED_INT, C_NULL)
end

function main()
    application = Application()
    EngineCore.push_layer(application.layer_stack, CustomLayer())
    EngineCore.push_overlay(application.layer_stack, ImGUI.ImGuiLayer())
    application |> run
end
main()

end
