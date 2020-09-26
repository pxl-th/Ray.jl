module Sandbox2D

using GLFW
using CImGui
using CImGui.CSyntax
using GeometryBasics
using Ray

struct CustomLayer <: Ray.Layer
    texture::Ray.Renderer2D.Backend.Texture2D
    controller::Ray.OrthographicCameraController
end

function CustomLayer()
    Ray.Renderer2D.init()
    texture = Ray.Renderer2D.Backend.Texture2D(raw"C:\Users\tonys\Downloads\tr.png")
    controller = Ray.OrthographicCameraController(1280f0 / 720f0, true)
    CustomLayer(texture, controller)
end

function Ray.on_update(cs::CustomLayer, timestep::Float64)
    timestep = Float32(timestep)

    Ray.OrthographicCameraModule.on_update(cs.controller, timestep |> Float32)

    Ray.Backend.set_clear_color(0.1, 0.1, 0.1, 1)
    Ray.Backend.clear()

    Ray.Renderer2D.begin_scene(cs.controller.camera)

    Ray.Renderer2D.draw_quad(Vec2f0(1, 1), Vec2f0(1, 4), Vec4f0(0.8, 0.3, 0.2, 1.0))
    Ray.Renderer2D.draw_quad(Vec2f0(-3, 0), Vec2f0(4, 1), Vec4f0(0.2, 0.3, 0.8, 1.0))
    Ray.Renderer2D.draw_quad(Vec2f0(-4, 3), Vec2f0(4, 1), Vec4f0(0.3, 0.8, 0.2, 1.0))

    Ray.Renderer2D.draw_quad(Vec3f0(0, 0, -0.1), Vec2f0(5, 5), cs.texture)

    Ray.Renderer2D.end_scene()
end

function Ray.EngineCore.on_event(cs::CustomLayer, event::Ray.Event.MouseScrolled)
    Ray.OrthographicCameraModule.on_event(cs.controller, event)
end

function Ray.EngineCore.on_event(cs::CustomLayer, event::Ray.Event.WindowResize)
    Ray.OrthographicCameraModule.on_event(cs.controller, event)
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
