module Renderer
export
    BufferElement, BufferLayout, size, length,
    submit, begin_scene, end_scene, RendererState,
    ShaderLibrary, add!, load!, get, exists

using LinearAlgebra: I
using StaticArrays
using GeometryBasics
using GLFW


include("../../backend/Abstractions.jl")
include("../../backend/opengl/OpenGL.jl")

using Ray.Input
using Ray.Event
using Ray.OrthographicCameraModule

using .Abstractions
using .OpenGLBackend

const Backend = OpenGLBackend

include("shader.jl")

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
    va::Abstractions.VertexArray, transform::Mat4f0 = Mat4f0(I),
)
    shader |> Backend.bind
    Backend.upload_uniform(shader, "u_ViewProjection", renderer.scene_data.view_projection)
    Backend.upload_uniform(shader, "u_Transform", transform)

    va |> Backend.bind
    Backend.draw_indexed(va)
end

const STATE = RendererState(SceneData(zeros(Mat4f0)))

end
