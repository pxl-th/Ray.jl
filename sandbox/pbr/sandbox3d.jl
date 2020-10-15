module Sandbox3D

using LinearAlgebra: I
using GLFW
using ModernGL
using CImGui
using CImGui.CSyntax
using GeometryBasics
using Ray

include("primitives.jl")
include("hdr_to_cubemap.jl")
include("prefilter.jl")
include("integrate_brdf.jl")

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

    cubemap::Ray.Backend.Cubemap
    irradiance::Ray.Backend.Cubemap
    prefiltered_cubemap::Ray.Backend.Cubemap
    brdf_lut::Ray.Backend.Texture2D

    skybox_shader::Ray.Backend.Shader

    sphere::Ray.Backend.VertexArray
    shader::Ray.Backend.Shader
    material::Material

    lights::Vector{Light}
end

function CustomLayer(width::Integer, height::Integer)
    irradiance_map = Ray.Backend.Texture2D(
        raw"C:\Users\tonys\projects\julia\Ray\assets\textures\brooklyn-bridge-irradiance\bbp-2k.hdr",
        # raw"C:\Users\tonys\projects\julia\Ray\assets\textures\Newport_Loft\Newport_Loft_Ref.hdr",
        GL_UNSIGNED_SHORT, internal_format=GL_RGB16F, data_format=GL_RGB,
    )

    cubemap, irradiance = hdr_to_cubemap(irradiance_map)
    Ray.Backend.delete(irradiance_map)
    prefiltered_cubemap = prefilter(cubemap)
    brdf_lut = integrate_brdf()

    Ray.Backend.set_viewport(width, height)

    fb = Ray.Backend.Framebuffer(width, height)
    screen = get_screen_plane()
    cubebox = get_cubebox()
    sphere = uv_sphere()

    screen_shader = Ray.Backend.Shader(raw"C:\Users\tonys\projects\julia\Ray\assets\shaders\framebuffer.glsl")
    skybox_shader = Ray.Backend.Shader(raw"C:\Users\tonys\projects\julia\Ray\assets\shaders\skybox.glsl")
    shader = Ray.Backend.Shader(raw"C:\Users\tonys\projects\julia\Ray\assets\shaders\pbr.glsl")

    controller = Ray.PerspectiveCameraController(
        aspect_ratio=Float32(width / height), speed=10f0,
    )
    # TODO more advanced texture format deduction

    # albedo = Ray.Backend.Texture2D(raw"C:\Users\tonys\Downloads\scuffed-plastic-1-Unreal-Engine\scuffed-plastic4-alb.png")
    # metallic = Ray.Backend.Texture2D(raw"C:\Users\tonys\Downloads\scuffed-plastic-1-Unreal-Engine\scuffed-plastic-metal.png")
    # normal = Ray.Backend.Texture2D(raw"C:\Users\tonys\Downloads\scuffed-plastic-1-Unreal-Engine\scuffed-plastic-normal.png")
    # roughness = Ray.Backend.Texture2D(raw"C:\Users\tonys\Downloads\scuffed-plastic-1-Unreal-Engine\scuffed-plastic-rough.png")
    # ao = Ray.Backend.Texture2D(
    #     raw"C:\Users\tonys\Downloads\scuffed-plastic-1-Unreal-Engine\scuffed-plastic-ao.png",
    #     GL_UNSIGNED_SHORT, internal_format=GL_RGB16F, data_format=GL_RGB,
    # )

    albedo = Ray.Backend.Texture2D(raw"C:\Users\tonys\Downloads\light-gold-ue\lightgold_albedo.png")
    metallic = Ray.Backend.Texture2D(raw"C:\Users\tonys\Downloads\light-gold-ue\lightgold_metallic.png")
    normal = Ray.Backend.Texture2D(raw"C:\Users\tonys\Downloads\light-gold-ue\lightgold_normal-dx.png")
    roughness = Ray.Backend.Texture2D(raw"C:\Users\tonys\Downloads\light-gold-ue\lightgold_roughness.png")
    ao = Ray.Backend.Texture2D(1, 1, internal_format=GL_RED, data_format=GL_RED)
    Ray.Backend.set_data!(ao, UInt8[0xff], 1)

    material = Material(albedo, metallic, roughness, normal, ao)

    lights = [
        Light(Point3f0(0f0, 0f0, 10f0), Point3f0(150f0, 150f0, 150f0)),
        Light(Point3f0(10f0, 0f0, 10f0), Point3f0(150f0, 150f0, 150f0)),
        Light(Point3f0(0f0, 10f0, 10f0), Point3f0(150f0, 150f0, 150f0)),
        Light(Point3f0(10f0, 10f0, 10f0), Point3f0(150f0, 150f0, 150f0)),
    ]
    CustomLayer(
        fb, screen, screen_shader,
        controller,
        cubebox,
        cubemap, irradiance, prefiltered_cubemap, brdf_lut,
        skybox_shader,
        sphere, shader, material,
        lights,
    )
end

function Ray.on_update(cs::CustomLayer, timestep::Float64)
    timestep = Float32(timestep)

    Ray.PerspectiveCameraModule.on_update(cs.controller, timestep)

    cs.fb |> Ray.Backend.bind

    Ray.Backend.enable_depth()
    Ray.Backend.set_clear_color(1.0, 0.0, 1.0, 1)
    Ray.Backend.clear()

    Ray.Renderer.begin_scene(cs.controller.camera)

    cs.shader |> Ray.Backend.bind
    Ray.Backend.upload_uniform(cs.shader, "u_CamPos", cs.controller.camera.position)
    Ray.Backend.upload_uniform(cs.shader, "u_CamPos", cs.controller.camera.position)

    Ray.Backend.upload_uniform(cs.shader, "u_IrradianceMap", 6)
    Ray.Backend.upload_uniform(cs.shader, "u_PrefilterMap", 7)
    Ray.Backend.upload_uniform(cs.shader, "u_BrdfLUT", 8)
    Ray.Backend.bind(cs.irradiance, 6)
    Ray.Backend.bind(cs.prefiltered_cubemap, 7)
    Ray.Backend.bind(cs.brdf_lut, 8)

    upload_uniform(cs.shader, "u_Material", cs.material)
    for (i, light) in enumerate(cs.lights)
        Ray.Backend.upload_uniform(cs.shader, "u_LightPos[$(i - 1)]", light.position)
        Ray.Backend.upload_uniform(cs.shader, "u_LightColors[$(i - 1)]", light.color)
    end

    Ray.Renderer.submit(cs.shader, cs.sphere)

    # Draw skybox.
    glDepthFunc(GL_LEQUAL)
    cs.skybox_shader |> Ray.Backend.bind
    cs.cubemap |> Ray.Backend.bind
    # cs.irradiance |> Ray.Backend.bind
    # cs.prefiltered_cubemap |> Ray.Backend.bind

    Ray.Backend.upload_uniform(cs.skybox_shader, "u_EnvironmentMap", 0)
    Ray.Backend.upload_uniform(
        cs.skybox_shader, "u_Projection", cs.controller.camera.projection,
    )
    Ray.Backend.upload_uniform(
        cs.skybox_shader, "u_View", cs.controller.camera.view,
    )

    cs.cubebox |> Ray.Backend.bind
    cs.cubebox |> Ray.Backend.draw_indexed
    glDepthFunc(GL_LESS)

    Ray.Renderer.end_scene()
    cs.fb |> Ray.Backend.unbind

    # Render screen.
    Ray.Backend.disable_depth()
    Ray.Backend.set_clear_color(0, 0, 0, 1)
    Ray.Backend.clear(GL_COLOR_BUFFER_BIT)

    cs.screen_shader |> Ray.Backend.bind
    cs.fb.attachments[GL_COLOR_ATTACHMENT0].attachment |> Ray.Backend.bind
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
