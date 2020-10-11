module Sandbox3D

using LinearAlgebra: I
using GLFW
using ModernGL
using CImGui
using CImGui.CSyntax
using GeometryBasics
using Ray

include("primitives.jl")

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


mutable struct CustomLayer <: Ray.Layer
    fb::Ray.Backend.Framebuffer
    screen::Ray.Backend.VertexArray
    screen_shader::Ray.Backend.Shader

    controller::Ray.PerspectiveCameraController

    cubebox::Ray.Backend.VertexArray
    cubebox_shader::Ray.Backend.Shader
    irradiance_shader::Ray.Backend.Shader
    irradiance_map::Ray.Backend.Texture2D

    va::Ray.Backend.VertexArray
    shader::Ray.Backend.Shader
    material::Material

    lights::Vector{Light}
end

function CustomLayer(width::Integer, height::Integer)
    screen = get_screen_plane()
    screen_shader = Ray.Backend.Shader(raw"C:\Users\tonys\projects\julia\Ray\assets\shaders\framebuffer.glsl")
    fb = Ray.Backend.Framebuffer(Ray.Renderer.FramebufferSpec(width, height, 1))

    cubebox = get_cubebox()
    cubemap_shader = Ray.Backend.Shader(raw"C:\Users\tonys\projects\julia\Ray\assets\shaders\cubemap.glsl")
    cubemap = Ray.Backend.Cubemap(512, 512)
    irradiance_shader = Ray.Backend.Shader(raw"C:\Users\tonys\projects\julia\Ray\assets\shaders\from-rectangle-to-cubemap.glsl")
    irradiance_map = Ray.Backend.Texture2D(
        raw"C:\Users\tonys\projects\julia\Ray\assets\textures\brooklyn-bridge-irradiance\bbp-2k.hdr",
        GL_UNSIGNED_SHORT, internal_format=GL_RGB16F, data_format=GL_RGB,
    )

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
        cubebox, cubemap_shader,
        irradiance_shader, irradiance_map,
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

    # Visualize cubebox.
    cs.irradiance_shader |> Ray.Backend.bind
    cs.irradiance_map |> Ray.Backend.bind
    Ray.Backend.upload_uniform(cs.irradiance_shader, "u_EquirectangularMap", 0)
    Ray.Backend.upload_uniform(cs.irradiance_shader, "u_ViewProjection", cs.controller.camera.view_projection)

    cs.cubebox |> Ray.Backend.bind
    cs.cubebox |> Ray.Backend.draw_indexed

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
