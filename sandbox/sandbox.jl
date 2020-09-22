module Sandbox

using GLFW
using CImGui
using CImGui.CSyntax
using GeometryBasics
using Ray

struct CustomLayer <: Ray.Layer
    va::Ray.Backend.VertexArray
    texture::Ray.Backend.Texture2D
    shader_library::Ray.ShaderLibrary
    controller::Ray.OrthographicCameraController
    square_position::Vector{Float32}
end

function CustomLayer()
    controller = Ray.OrthographicCameraController(1280f0 / 720f0, true)

    library = Ray.ShaderLibrary()
    Ray.load!(library, raw"C:\Users\tonys\projects\julia\Ray\assets\shaders\texture.glsl")
    texture = Ray.Backend.Texture2D(raw"C:\Users\tonys\Downloads\tr.png")

    layout = Ray.BufferLayout([
        Ray.BufferElement(Point3f0, "a_Position"),
        Ray.BufferElement(Point2f0, "a_TexCoord"),
    ])
    data = Float32[
        -0.5, -0.5, 0.0, 0.0, 0.0,
         0.5, -0.5, 0.0, 1.0, 0.0,
         0.5,  0.5, 0.0, 1.0, 1.0,
        -0.5,  0.5, 0.0, 0.0, 1.0,
    ]
    indices = UInt32[0, 1, 2, 2, 3, 0]

    va = Ray.Backend.VertexArray()
    ib = Ray.Backend.IndexBuffer(indices)
    vb = Ray.Backend.VertexBuffer(data, sizeof(data))

    Ray.Backend.set_layout(vb, layout)
    Ray.Backend.add_vertex_buffer(va, vb)
    Ray.Backend.set_index_buffer(va, ib)

    shader = Ray.Renderer.get(library, "texture")
    Ray.Backend.bind(shader)
    Ray.Backend.upload_uniform(shader, "u_Texture", 0)

    CustomLayer(va, texture, library, controller, Float32[0, 0, 0])
end

function Ray.on_update(cs::CustomLayer, timestep::Float64)
    timestep = Float32(timestep)

    Ray.Renderer.on_update(cs.controller, timestep |> Float32)

    Ray.Backend.set_clear_color(0.1, 0.1, 0.1, 1)
    Ray.Backend.clear()

    Ray.begin_scene(Ray.Renderer.STATE, cs.controller.camera)

    transform = Ray.Renderer.translation(cs.square_position)

    shader = Ray.Renderer.get(cs.shader_library, "texture")
    Ray.Backend.bind(cs.texture)
    Ray.submit(Ray.Renderer.STATE, shader, cs.va, transform)
    Ray.end_scene(Ray.Renderer.STATE)
end

function Ray.EngineCore.on_event(cs::CustomLayer, event::Ray.Event.MouseScrolled)
    Ray.Renderer.on_event(cs.controller, event)
end

function Ray.EngineCore.on_event(cs::CustomLayer, event::Ray.Event.WindowResize)
    Ray.Renderer.on_event(cs.controller, event)
end

function Ray.on_imgui_render(cs::CustomLayer, timestep::Float64)
    CImGui.Begin("Control")
    CImGui.SliderFloat3("Box Position", cs.square_position, -5f0, 5f0)
    CImGui.End()
end

function main()
    application = Ray.Application()
    Ray.push_layer(application.layer_stack, CustomLayer())
    application |> Ray.run
end
main()

end
