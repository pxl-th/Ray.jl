module Ray

import Assimp
using GeometryBasics
using LinearAlgebra
using StaticArrays
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
include("backend/Abstractions.jl")
include("backend/opengl/OpenGL.jl")

const Backend = OpenGLBackend

include("engine/events/Event.jl")
include("engine/core/input.jl")
include("engine/core/Transformations.jl")

include("engine/renderer/OrthographicCamera.jl")
include("engine/renderer/PerspectiveCamera.jl")
using .OrthographicCameraModule
using .PerspectiveCameraModule

include("engine/core/Core.jl")
include("engine/imgui/ImGUI.jl")

using .Abstractions: BufferElement, BufferLayout
using .Transformations
using .Event
using .Input
using .EngineCore
using .ImGUI

include("engine/renderer/Renderer.jl")
include("engine/renderer/Renderer2D.jl")

include("loader/model.jl")

function get_assets_path()::String
    assets_path = joinpath(@__DIR__, "..", "assets")
    @assert isdir(assets_path) "Assets path does not exist!"
    assets_path
end

function get_asset_shader_path(name::String)::String
    !endswith(name, ".glsl") && (name = "$(name).glsl")
    shader_path = joinpath(get_assets_path(), "shaders", name)
    !isfile(shader_path) && error("No [$name] shader found in assets.")
    shader_path
end

get_asset_shader(name::String)::Backend.Shader =
    name |> get_asset_shader_path |> Backend.Shader

mutable struct Application
    window::EngineCore.Window
    gui_layer::ImGuiLayer
    layer_stack::EngineCore.LayerStack

    running::Bool
    minimized::Bool
    last_frame_time::Float64
end

function Application(
    width::Integer = 1280, height::Integer = 720, name::String = "Ray",
)
    props = EngineCore.WindowProps(width=width, height=height, title=name)
    window = EngineCore.Window(props)

    app = Application(
        window, ImGuiLayer(), EngineCore.LayerStack(), true, false, 0.0,
    )
    app |> set_application

    Backend.init(window.window)
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
