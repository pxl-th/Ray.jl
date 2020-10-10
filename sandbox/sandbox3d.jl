module Sandbox3D

using LinearAlgebra: I
using GLFW
using ModernGL
using CImGui
using CImGui.CSyntax
using GeometryBasics
using Ray

function uv_sphere(steps = 32, scale = 1f0)
    data = Float32[]
    position = Point3f0(0f0, 1f0, 0f0) * scale
    append!(data, position)
    append!(data, Point2f0(0f0, 0f0))
    append!(data, position)

    num_vertices = 0
    for j in 0:(steps - 2)
        polar = π * (j + 1) / steps
        sp = sin(polar)
        cp = cos(polar)
        for i in 0:(steps - 1)
            azimuth = 2f0 * π * i / steps
            sa = sin(azimuth)
            ca = cos(azimuth)

            position = Point3f0(sp * ca, cp, sp * sa) * scale
            uv = Point2f0(i / steps, j / steps)
            append!(data, position)
            append!(data, uv)
            append!(data, position)

            num_vertices += 1
        end
    end
    position = Point3f0(0f0, -1f0, 0f0) * scale
    append!(data, position)
    append!(data, Point2f0(0f0, 0f0))
    append!(data, position)

    indices = UInt32[]
    for i in 0:(steps - 1)
        a = i + 1
        b = (i + 1) % steps + 1
        append!(indices, Point3f0(0, b, a))
    end

    for j in 0:(steps - 3)
        a_start = j * steps + 1
        b_start = (j + 1) * steps + 1
        for i in 0:(steps - 1)
            a = a_start + i
            a1 = a_start + (i + 1) % steps
            b = b_start + i
            b1 = b_start + (i + 1) % steps
            append!(indices, Point3f0(a, a1, b))
            append!(indices, Point3f0(b, a1, b1))
        end
    end

    for i in 0:(steps - 1)
        a = i + steps * (steps - 2) + 1
        b = (i + 1) % steps + steps * (steps - 2) + 1
        append!(indices, Point3f0(num_vertices - 1, a, b))
    end

    va = Ray.Backend.VertexArray()
    vb = Ray.Backend.VertexBuffer(data, sizeof(data))
    ib = Ray.Backend.IndexBuffer(indices)

    Ray.Backend.set_layout(vb, Ray.Renderer.BufferLayout([
        Ray.Renderer.BufferElement(Point3f0, "a_Position"),
        Ray.Renderer.BufferElement(Point2f0, "a_TexCoord"),
        Ray.Renderer.BufferElement(Vec3f0, "a_Normal"),
    ]))
    Ray.Backend.add_vertex_buffer(va, vb)
    Ray.Backend.set_index_buffer(va, ib)

    va
end

struct Material
    albedo::Ray.Backend.Texture2D
    metallic::Ray.Backend.Texture2D
    roughness::Ray.Backend.Texture2D
    normal::Ray.Backend.Texture2D
    ao::Ray.Backend.Texture2D
end

struct Light
    position::Point3f0
    color::Point3f0
end

function upload_uniform(
    shader::Ray.Backend.Shader, name::String, material::Material,
    slot::Integer = 0,
)
    Ray.Backend.bind(material.albedo, slot)
    Ray.Backend.bind(material.metallic, slot + 1)
    Ray.Backend.bind(material.roughness, slot + 2)
    Ray.Backend.bind(material.normal, slot + 3)
    Ray.Backend.bind(material.ao, slot + 4)

    Ray.Backend.upload_uniform(shader, "$name.albedo", slot)
    Ray.Backend.upload_uniform(shader, "$name.metallic", slot + 1)
    Ray.Backend.upload_uniform(shader, "$name.roughness", slot + 2)
    Ray.Backend.upload_uniform(shader, "$name.normal", slot + 3)
    Ray.Backend.upload_uniform(shader, "$name.ao", slot + 4)
end

function get_screen_plane()
    data = Float32[
        -1,-1, 0, 0, 0,
         1,-1, 0, 1, 0,
         1, 1, 0, 1, 1,
        -1, 1, 0, 0, 1,
    ]
    indices = UInt32[0, 1, 2, 2, 3, 0]

    va = Ray.Backend.VertexArray()
    vb = Ray.Backend.VertexBuffer(data, sizeof(data))
    ib = Ray.Backend.IndexBuffer(indices)

    Ray.Backend.set_layout(vb, Ray.Renderer.BufferLayout([
        Ray.Renderer.BufferElement(Point3f0, "a_Position"),
        Ray.Renderer.BufferElement(Point2f0, "a_TexCoord"),
    ]))
    Ray.Backend.add_vertex_buffer(va, vb)
    Ray.Backend.set_index_buffer(va, ib)

    va
end

mutable struct CustomLayer <: Ray.Layer
    fb::Ray.Backend.Framebuffer
    screen::Ray.Backend.VertexArray
    screen_shader::Ray.Backend.Shader

    controller::Ray.PerspectiveCameraController

    va::Ray.Backend.VertexArray
    shader::Ray.Backend.Shader
    material::Material

    lights::Vector{Light}
end

function CustomLayer(width::Integer, height::Integer)
    screen = get_screen_plane()
    screen_shader = Ray.Backend.Shader(raw"C:\Users\tonys\projects\julia\Ray\assets\shaders\framebuffer.glsl")
    fb = Ray.Backend.Framebuffer(Ray.Renderer.FramebufferSpec(width, height, 1))

    controller = Ray.PerspectiveCameraController(
        aspect_ratio=Float32(width / height), speed=10f0,
    )
    va = uv_sphere()

    albedo = Ray.Backend.Texture2D(raw"C:\Users\tonys\Downloads\rust\rustediron2_basecolor.png")
    metallic = Ray.Backend.Texture2D(raw"C:\Users\tonys\Downloads\rust\rustediron2_metallic.png")
    normal = Ray.Backend.Texture2D(raw"C:\Users\tonys\Downloads\rust\rustediron2_normal.png")
    roughness = Ray.Backend.Texture2D(raw"C:\Users\tonys\Downloads\rust\rustediron2_roughness.png")
    ao = Ray.Backend.Texture2D(1, 1, internal_format=GL_RED, data_format=GL_RED)
    Ray.Backend.set_data!(ao, UInt8[0xff], 1)

    material = Material(albedo, metallic, roughness, normal, ao)
    shader = Ray.Backend.Shader(raw"C:\Users\tonys\projects\julia\Ray\assets\shaders\pbr-color.glsl")

    lights = [Light(Point3f0(0f0, 0f0, 10f0), Point3f0(150f0, 150f0, 150f0))]
    CustomLayer(
        fb, screen, screen_shader,
        controller,
        va, shader, material,
        lights,
    )
end

function Ray.on_update(cs::CustomLayer, timestep::Float64)
    timestep = Float32(timestep)

    Ray.PerspectiveCameraModule.on_update(cs.controller, timestep)

    cs.fb |> Ray.Backend.bind

    Ray.Backend.enable_depth()
    Ray.Backend.set_clear_color(0.9, 0.9, 0.9, 1)
    Ray.Backend.clear()

    Ray.Renderer.begin_scene(cs.controller.camera)

    cs.shader |> Ray.Backend.bind
    Ray.Backend.upload_uniform(cs.shader, "u_CamPos", cs.controller.camera.position)
    upload_uniform(cs.shader, "u_Material", cs.material)
    for (i, light) in enumerate(cs.lights)
        Ray.Backend.upload_uniform(cs.shader, "u_LightPos[$(i - 1)]", light.position)
        Ray.Backend.upload_uniform(cs.shader, "u_LightColors[$(i - 1)]", light.color)
    end

    Ray.Renderer.submit(cs.shader, cs.va)
    Ray.Renderer.end_scene()
    cs.fb |> Ray.Backend.unbind

    # Render screen.
    Ray.Backend.disable_depth()
    Ray.Backend.set_clear_color(0, 0, 0, 1)
    Ray.Backend.clear(GL_COLOR_BUFFER_BIT)

    cs.screen_shader |> Ray.Backend.bind
    Ray.Backend.bind(cs.fb.color_attachment, 0)
    Ray.Backend.upload_uniform(cs.screen_shader, "u_ScreenTexture", 0)

    cs.screen |> Ray.Backend.bind
    cs.screen |> Ray.Backend.draw_indexed
end

function Ray.EngineCore.on_event(cs::CustomLayer, event::Ray.Event.MouseScrolled)
    Ray.PerspectiveCameraModule.on_event(cs.controller, event)
end

function Ray.EngineCore.on_event(cs::CustomLayer, event::Ray.Event.WindowResize)
    Ray.PerspectiveCameraModule.on_event(cs.controller, event)
    Ray.Backend.resize!(cs.fb, event.width |> UInt32, event.height |> UInt32)
end

function Ray.on_imgui_render(cs::CustomLayer, timestep::Float64)
    # CImGui.Begin("Control")
    # CImGui.Text("Henlo")
    # CImGui.End()
end

function main()
    application = Ray.Application()
    layer = CustomLayer(
        application.window.properties.width,
        application.window.properties.height,
    )
    Ray.push_layer(application.layer_stack, layer)
    application |> Ray.run
end
main()

end
