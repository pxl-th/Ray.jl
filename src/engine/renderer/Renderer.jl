module Renderer
export
    get_backend, set_backend,
    BufferElement, BufferLayout, size, length,
    submit, begin_scene, end_scene, RendererState,
    OrthographicCamera, set_rotation!, set_position!

using StaticArrays
using GeometryBasics

include("../../backend/Abstractions.jl")
include("../../backend/opengl/OpenGL.jl")

using .Abstractions
using .OpenGLBackend

let backend = OpenGLBackend
    global get_backend() = backend
    global set_backend(new_backend) = backend = new_backend
end

include("orthographic_camera.jl")

mutable struct SceneData
    view_projection::Mat4f0
end

struct RendererState
    scene_data::SceneData
end

function begin_scene(renderer::RendererState, camera::OrthographicCamera)
    renderer.scene_data.view_projection = camera.view_projection
end

function end_scene(renderer::RendererState) end

function submit(
    renderer::RendererState, shader::Abstractions.Shader,
    va::Abstractions.VertexArray,
)
    shader |> get_backend().bind
    get_backend().upload_uniform(
        shader, "u_ViewProjection", renderer.scene_data.view_projection,
    )
    va |> get_backend().bind
    get_backend().draw_indexed(va)
end

const STATE = RendererState(SceneData(zeros(Mat4f0)))

end
