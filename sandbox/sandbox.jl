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
    camera::Ray.OrthographicCamera
    square_position::Vector{Float32}
end

function CustomLayer()
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

    camera = Ray.OrthographicCamera(-1f0, 1f0, -1f0, 1f0)

    shader = Ray.Renderer.get(library, "texture")
    Ray.Backend.bind(shader)
    Ray.Backend.upload_uniform(shader, "u_Texture", 0)

    CustomLayer(va, texture, library, camera, Float32[0, 0, 0])
end

function Ray.on_update(cs::CustomLayer, timestep::Float64)
    timestep = Float32(timestep)
    camera_speed = 10f0 * timestep
    rotation_speed = 180f0 * timestep

    new_position = cs.camera.position
    if Ray.is_key_pressed(GLFW.KEY_W)
        new_position += Vec3f0(0.0, camera_speed, 0.0)
    elseif Ray.is_key_pressed(GLFW.KEY_S)
        new_position -= Vec3f0(0.0, camera_speed, 0.0)
    end
    if Ray.is_key_pressed(GLFW.KEY_A)
        new_position -= Vec3f0(camera_speed, 0.0, 0.0)
    elseif Ray.is_key_pressed(GLFW.KEY_D)
        new_position += Vec3f0(camera_speed, 0.0, 0.0)
    end

    new_rotation = cs.camera.rotation
    if Ray.is_key_pressed(GLFW.KEY_J)
        new_rotation -= rotation_speed
    elseif Ray.is_key_pressed(GLFW.KEY_K)
        new_rotation += rotation_speed
    end

    Ray.set_position!(cs.camera, new_position)
    Ray.set_rotation!(cs.camera, new_rotation)

    Ray.Backend.set_clear_color(0.1, 0.1, 0.1, 1)
    Ray.Backend.clear()

    Ray.begin_scene(Ray.Renderer.STATE, cs.camera)

    transform = Ray.Renderer.translation(cs.square_position)

    shader = Ray.Renderer.get(cs.shader_library, "texture")
    Ray.Backend.bind(cs.texture)
    Ray.submit(Ray.Renderer.STATE, shader, cs.va, transform)
    Ray.end_scene(Ray.Renderer.STATE)
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
