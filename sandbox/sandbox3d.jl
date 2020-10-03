module Sandbox3D

using LinearAlgebra: I
using GLFW
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
    albedo::Point3f0
    metallic::Float32
    roughness::Float32
    ao::Float32
end

struct Light
    position::Point3f0
    color::Point3f0
end

function upload_uniform(
    shader::Ray.Backend.Shader, name::String, material::Material,
)
    Ray.Backend.upload_uniform(shader, "$name.albedo", material.albedo)
    Ray.Backend.upload_uniform(shader, "$name.metallic", material.metallic)
    Ray.Backend.upload_uniform(shader, "$name.roughness", material.roughness)
    Ray.Backend.upload_uniform(shader, "$name.ao", material.ao)
end

mutable struct CustomLayer <: Ray.Layer
    controller::Ray.PerspectiveCameraController
    va::Ray.Backend.VertexArray
    shader::Ray.Backend.Shader
    materials::Vector{Material}
    lights::Vector{Light}
end

function CustomLayer()
    controller = Ray.PerspectiveCameraController(;aspect_ratio=1280f0 / 720f0, speed=20f0)
    va = uv_sphere(32)
    # shader = Ray.Backend.Shader(raw"C:\Users\tonys\projects\julia\Ray\assets\shaders\single_color.glsl")
    shader = Ray.Backend.Shader(raw"C:\Users\tonys\projects\julia\Ray\assets\shaders\pbr-color.glsl")

    lights = Light[
        Light(Point3f0(-10f0, 10f0, 10f0), Point3f0(300f0, 300f0, 300f0)),
        Light(Point3f0(10f0, 10f0, 10f0), Point3f0(300f0, 300f0, 300f0)),
        Light(Point3f0(-10f0, -10f0, 10f0), Point3f0(300f0, 300f0, 300f0)),
        Light(Point3f0(10f0, -10f0, 10f0), Point3f0(300f0, 300f0, 300f0)),
    ]
    materials = [
        Material(Point3f0(1f0, 0f0, 0f0), i, max(0.1f0, i), 1f0)
        for i in 0:0.1:1
    ]
    CustomLayer(controller, va, shader, materials, lights)
end

function Ray.on_update(cs::CustomLayer, timestep::Float64)
    timestep = Float32(timestep)

    Ray.PerspectiveCameraModule.on_update(cs.controller, timestep)

    Ray.Backend.set_clear_color(0.1, 0.1, 0.1, 1)
    Ray.Backend.clear()

    Ray.Renderer.begin_scene(cs.controller.camera)

    cs.shader |> Ray.Backend.bind
    Ray.Backend.upload_uniform(cs.shader, "u_CamPos", cs.controller.camera.position)

    for (i, light) in enumerate(cs.lights)
        Ray.Backend.upload_uniform(cs.shader, "u_LightPos[$(i - 1)]", light.position)
        Ray.Backend.upload_uniform(cs.shader, "u_LightColors[$(i - 1)]", light.color)
    end

    for (i, material) in enumerate(cs.materials)
        upload_uniform(cs.shader, "u_Material", material)
        Ray.Renderer.submit(
            cs.shader, cs.va, Ray.translation(3 * (i - 1) |> Float32, 0f0, 0f0),
        )
    end

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
