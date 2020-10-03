module Sandbox3D

using LinearAlgebra: I
using GLFW
using CImGui
using CImGui.CSyntax
using GeometryBasics
using Ray

mutable struct CustomLayer <: Ray.Layer
    controller::Ray.PerspectiveCameraController
    va::Ray.Backend.VertexArray
    shader::Ray.Backend.Shader
end

function CustomLayer()
    controller = Ray.PerspectiveCameraController(;aspect_ratio=1280f0 / 720f0)

    vertices = Point3f0[
        Point3f0(-0.5f0, -0.5f0, 0f0),
        Point3f0(0.5f0, -0.5f0, 0f0),
        Point3f0(0.5f0,  0.5f0, 0f0),
        Point3f0(-0.5f0,  0.5f0, 0f0),
    ]
    indices = UInt32[0, 1, 2, 2, 3, 0]

    va = Ray.Backend.VertexArray()
    vb = Ray.Backend.VertexBuffer(vertices, sizeof(vertices))
    ib = Ray.Backend.IndexBuffer(indices)

    Ray.Backend.set_layout(vb, Ray.Renderer.BufferLayout([
        Ray.Renderer.BufferElement(Point3f0, "a_Position"),
    ]))
    Ray.Backend.add_vertex_buffer(va, vb)
    Ray.Backend.set_index_buffer(va, ib)

    shader = Ray.Backend.Shader(raw"C:\Users\tonys\projects\julia\Ray\assets\shaders\single_color.glsl")

    CustomLayer(controller, va, shader)
end

function Ray.on_update(cs::CustomLayer, timestep::Float64)
    timestep = Float32(timestep)

    Ray.PerspectiveCameraModule.on_update(cs.controller, timestep)

    Ray.Backend.set_clear_color(0.1, 0.1, 0.1, 1)
    Ray.Backend.clear()

    Ray.Renderer.begin_scene(cs.controller.camera)

    Ray.Renderer.submit(cs.shader, cs.va)

    Ray.Renderer.end_scene()
end

function Ray.EngineCore.on_event(cs::CustomLayer, event::Ray.Event.MouseScrolled)
    Ray.PerspectiveCameraModule.on_event(cs.controller, event)
end

function Ray.EngineCore.on_event(cs::CustomLayer, event::Ray.Event.WindowResize)
    Ray.PerspectiveCameraModule.on_event(cs.controller, event)
end

function Ray.on_imgui_render(cs::CustomLayer, timestep::Float64)
    CImGui.Begin("Control")
    CImGui.Text("Henlo")
    CImGui.End()
end

function main()
    application = Ray.Application()
    Ray.push_layer(application.layer_stack, CustomLayer())
    application |> Ray.run
end
main()

end
