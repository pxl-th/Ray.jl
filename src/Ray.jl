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
include("engine/renderer/Renderer.jl")
include("engine/events/Event.jl")
include("engine/core/Core.jl")
include("engine/imgui/ImGUI.jl")

using .Renderer
using .Event
using .EngineCore
using .ImGUI

Backend = Renderer.get_backend()


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
    vb::Backend.VertexBuffer
    ib::Backend.IndexBuffer
    va::UInt32
    shader::Backend.Shader
end

function CustomLayer()
    vertex_shader = raw"""
    #version 330 core

    layout (location = 0) in vec3 a_Position;
    layout (location = 1) in vec4 a_Color;

    out vec4 out_color;

    void main() {
        out_color = a_Color;
        gl_Position = vec4(a_Position, 1.0);
    }
    """
    fragment_shader = raw"""
    #version 330 core

    in vec4 out_color;

    layout (location = 0) out vec4 color;

    void main() {
        color = out_color;
    }
    """
    shader = Backend.Shader(vertex_shader, fragment_shader)

    layout = BufferLayout([
        BufferElement(Point3f0, "a_Position")
        BufferElement(Point4f0, "a_Color")
    ])
    triangle = Float32[
        -0.5, 0.0, 0.0, 0.8, 0.2, 0.3, 1.0,
         0.5, 0.0, 0.0, 0.2, 0.3, 0.8, 1.0,
         0.0, 0.5, 0.0, 0.3, 0.8, 0.2, 1.0,
    ]
    indices = UInt32[0, 1, 2]

    va = @ref glGenVertexArrays(1, RepUInt32)
    glBindVertexArray(va)

    vb = Backend.VertexBuffer(triangle, sizeof(triangle))
    vb |> Backend.bind
    Backend.set_layout(vb, layout)

    ib = Backend.IndexBuffer(indices)
    ib |> Backend.bind

    for (i, element) in enumerate(vb.layout.elements)
        glEnableVertexAttribArray(i - 1)
        glVertexAttribPointer(
            i - 1,
            length(element),
            Backend.get_base_type(element),
            element.normalized ? GL_TRUE : GL_FALSE,
            layout.stride,
            Ptr{Cvoid}(Int64(element.offset))
        )
    end

    CustomLayer(vb, ib, va, shader)
end

function EngineCore.on_update(cs::CustomLayer, timestep::Float64)
    cs.shader |> Backend.bind
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
