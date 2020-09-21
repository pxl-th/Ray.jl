module Sandbox

using GLFW
using CImGui
using CImGui.CSyntax
using GeometryBasics
using Ray

struct CustomLayer <: Ray.Layer
    va::Ray.Backend.VertexArray
    shader::Ray.Backend.Shader
    camera::Ray.OrthographicCamera
end

function CustomLayer()
    vertex_shader = raw"""
    #version 330 core

    layout (location = 0) in vec3 a_Position;
    layout (location = 1) in vec4 a_Color;

    uniform mat4 u_ViewProjection;

    out vec4 out_color;

    void main() {
        out_color = a_Color;
        gl_Position = u_ViewProjection * vec4(a_Position, 1.0);
    }
    """
    fragment_shader = raw"""
    #version 330 core

    in vec4 out_color;

    layout (location = 0) out vec4 color;

    void main() {
        color = out_color;
    }
    """
    shader = Ray.Backend.Shader(vertex_shader, fragment_shader)

    layout = Ray.BufferLayout([
        Ray.BufferElement(Point3f0, "a_Position")
        Ray.BufferElement(Point4f0, "a_Color")
    ])
    data = Float32[
        -0.5, -0.5, 0.0, 0.8, 0.2, 0.3, 1.0,
         0.5, -0.5, 0.0, 0.2, 0.3, 0.8, 1.0,
         0.5,  0.5, 0.0, 0.3, 0.8, 0.2, 1.0,
        -0.5,  0.5, 0.0, 0.9, 0.7, 0.6, 1.0,
    ]
    indices = UInt32[0, 1, 2, 2, 3, 0]

    va = Ray.Backend.VertexArray()
    ib = Ray.Backend.IndexBuffer(indices)
    vb = Ray.Backend.VertexBuffer(data, sizeof(data))

    Ray.Backend.set_layout(vb, layout)
    Ray.Backend.add_vertex_buffer(va, vb)
    Ray.Backend.set_index_buffer(va, ib)

    camera = Ray.OrthographicCamera(-5f0, 5f0, -5f0, 5f0)

    CustomLayer(va, shader, camera)
end

function Ray.on_update(cs::CustomLayer, timestep::Float64)
    new_position = cs.camera.position
    if Ray.is_key_pressed(GLFW.KEY_W)
        new_position += Vec3f0(0.0, 0.1, 0.0)
    elseif Ray.is_key_pressed(GLFW.KEY_S)
        new_position -= Vec3f0(0.0, 0.1, 0.0)
    end
    if Ray.is_key_pressed(GLFW.KEY_A)
        new_position -= Vec3f0(0.1, 0.0, 0.0)
    elseif Ray.is_key_pressed(GLFW.KEY_D)
        new_position += Vec3f0(0.1, 0.0, 0.0)
    end

    new_rotation = cs.camera.rotation
    if Ray.is_key_pressed(GLFW.KEY_J)
        new_rotation -= 1f0
    elseif Ray.is_key_pressed(GLFW.KEY_K)
        new_rotation += 1f0
    end

    Ray.set_position!(cs.camera, new_position)
    Ray.set_rotation!(cs.camera, new_rotation)

    Ray.Backend.set_clear_color(0.1, 0.1, 0.1, 1)
    Ray.Backend.clear()

    Ray.begin_scene(Ray.Renderer.STATE, cs.camera)
    Ray.submit(Ray.Renderer.STATE, cs.shader, cs.va)
    Ray.end_scene(Ray.Renderer.STATE)
end

function Ray.on_imgui_render(::CustomLayer, timestep::Float64)
    CImGui.Begin("Stats")
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
