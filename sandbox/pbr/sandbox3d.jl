module Sandbox3D

using LinearAlgebra: I
using GLFW
using ModernGL
using CImGui
using CImGui.CSyntax
using GeometryBasics
using Ray

include("primitives.jl")
include("pbr_precompute.jl")

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
    pbr_precompute::PBRPrecompute
    skybox_shader::Ray.Backend.Shader

    shader::Ray.Backend.Shader
    model::Ray.Model

    lights::Vector{Light}
    total_time::Float32
end

function CustomLayer(width::Integer, height::Integer)
    model_path = raw"C:\Users\tonys\projects\3d-models\mando-helmet"
    textures_path = joinpath(model_path, "Textures")
    model = Ray.load(joinpath(model_path, raw"source\Mando_Helmet.fbx"))

    helmet_material = Ray.Material(
        Ray.Backend.Texture2D(joinpath(textures_path, "Mando_Helm_Mat_Colour.png")),
        Ray.Backend.Texture2D(joinpath(textures_path, "Mando_Helm_Mat_Metallic.png")),
        Ray.Backend.Texture2D(joinpath(textures_path, "Mando_Helm_Mat_Roughness.png")),
        Ray.Backend.Texture2D(joinpath(textures_path, "Mando_Helm_Mat_Normal.png")),
        Ray.Backend.Texture2D(joinpath(textures_path, "Mando_Helm_Mat_AO.png")),
    )
    stand_material = Ray.Material(
        Ray.Backend.Texture2D(joinpath(textures_path, "Helmet_Stand_Mat_Colour.png")),
        Ray.Backend.Texture2D(joinpath(textures_path, "Helmet_Stand_Mat_Metallic.png")),
        Ray.Backend.Texture2D(joinpath(textures_path, "Helmet_Stand_Mat_Roughness.png")),
        Ray.Backend.Texture2D(joinpath(textures_path, "Helmet_Stand_Mat_Normal.png")),
        Ray.Backend.Texture2D(joinpath(textures_path, "Helmet_Stand_Mat_AO.png")),
    )
    glass_material = Ray.Material(
        Ray.Backend.Texture2D(joinpath(textures_path, "Glass_Mat_Colour.png"), GL_UNSIGNED_SHORT; internal_format=GL_RGB16F, data_format=GL_RGB),
        Ray.Backend.Texture2D(UInt8[0xff, 0xff, 0xff, 0xff], 1, 1),
        Ray.Backend.Texture2D(joinpath(textures_path, "Glass_Mat_Roughness.png")),
        Ray.Backend.Texture2D(joinpath(textures_path, "Glass_Mat_BakeNormal.png"), GL_UNSIGNED_SHORT; internal_format=GL_RGB16F, data_format=GL_RGB),
        Ray.Backend.Texture2D(joinpath(textures_path, "Glass_Mat_AO.png"), GL_UNSIGNED_SHORT; internal_format=GL_RGB16F, data_format=GL_RGB),
    )
    # 1 -- stand 2 -- glass 3 -- helmet
    model.materials[1] = stand_material
    model.materials[2] = glass_material
    model.materials[3] = helmet_material

    assets_directory = Ray.get_assets_path()

    irradiance_map = Ray.Backend.Texture2D(
        joinpath(assets_directory, "textures", "environment-maps", "circus.hdr"),
        GL_UNSIGNED_SHORT, internal_format=GL_RGB16F, data_format=GL_RGB,
    )
    pbr_precompute = precompute_pbr(irradiance_map)
    Ray.Backend.delete(irradiance_map)

    Ray.Backend.set_viewport(width, height)

    fb = Ray.Backend.Framebuffer(width, height)
    screen = get_screen_plane()
    cubebox = get_cubebox()
    sphere = uv_sphere()

    screen_shader = Ray.get_asset_shader("framebuffer")
    skybox_shader = Ray.get_asset_shader("skybox")
    shader = Ray.get_asset_shader("pbr")

    controller = Ray.PerspectiveCameraController(
        aspect_ratio=Float32(width / height), speed=20f0,
    )

    lights = [Light(Point3f0(20f0, 30f0, 30f0), Point3f0(10000f0, 10000f0, 10000f0))]
    CustomLayer(
        fb, screen, screen_shader,
        controller,
        cubebox, pbr_precompute,
        skybox_shader,
        shader,
        model,
        lights,
        0,
    )
end

function Ray.on_update(cs::CustomLayer, timestep::Float64)
    timestep = Float32(timestep)
    cs.total_time += timestep

    Ray.PerspectiveCameraModule.on_update(cs.controller, timestep)

    cs.fb |> Ray.Backend.bind

    Ray.Backend.enable_depth()
    Ray.Backend.set_clear_color(1.0, 0.0, 1.0, 1)
    Ray.Backend.clear()

    Ray.begin_scene(cs.controller.camera)

    cs.shader |> Ray.Backend.bind
    Ray.Backend.upload_uniform(cs.shader, "u_CamPos", cs.controller.camera.position)
    Ray.Backend.upload_uniform(cs.shader, "u_IrradianceMap", 6)
    Ray.Backend.upload_uniform(cs.shader, "u_PrefilterMap", 7)
    Ray.Backend.upload_uniform(cs.shader, "u_BrdfLUT", 8)
    Ray.Backend.bind(cs.pbr_precompute.irradiance, 6)
    Ray.Backend.bind(cs.pbr_precompute.prefiltered, 7)
    Ray.Backend.bind(cs.pbr_precompute.brdf_lut, 8)
    for (i, light) in enumerate(cs.lights)
        Ray.Backend.upload_uniform(cs.shader, "u_LightPos[$(i - 1)]", light.position)
        Ray.Backend.upload_uniform(cs.shader, "u_LightColors[$(i - 1)]", light.color)
    end

    Ray.draw(
        cs.model, cs.shader, "u_Material",
        cs.controller.camera.view_projection,
        Ray.Transformations.rotation_y(0.2 * cs.total_time),
    )

    # Draw skybox.
    glDepthFunc(GL_LEQUAL)
    cs.skybox_shader |> Ray.Backend.bind
    cs.pbr_precompute.prefiltered |> Ray.Backend.bind
    # cs.pbr_precompute.environment |> Ray.Backend.bind

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

    # Ray.end_scene()
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

function Ray.EngineCore.on_event(cs::CustomLayer, event::Ray.Event.KeyPressed)
    if event.key == GLFW.KEY_M
        Ray.Backend.show_cursor(Ray.get_application() |> Ray.native_window)
    elseif event.key == GLFW.KEY_K
        Ray.Backend.hide_cursor(Ray.get_application() |> Ray.native_window)
    end
end

function Ray.on_imgui_render(cs::CustomLayer, timestep::Float64)
    # CImGui.Begin("Info")
    # CImGui.Text("Camera position: $(cs.controller.camera.position)")
    # CImGui.End()
end

function main()
    application = Ray.Application(1920, 1020)
    layer = CustomLayer(
        application.window.properties.width,
        application.window.properties.height,
    )
    Ray.push_layer(application.layer_stack, layer)
    application |> Ray.run
end
main()

end
