module Renderer
export
    BufferElement, BufferLayout, size, length,
    submit, begin_scene, end_scene,
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
using Ray.PerspectiveCameraModule

using .Abstractions
using .OpenGLBackend

const Backend = OpenGLBackend

include("shader.jl")

mutable struct SceneData
    view_projection::Mat4f0
end

const State = SceneData(zeros(Mat4f0))

function begin_scene(camera::PerspectiveCamera)
    State.view_projection = camera.view_projection
end

function begin_scene(camera::OrthographicCamera)
    State.view_projection = camera.view_projection
end

function end_scene() end

function submit(
    shader::Abstractions.Shader,
    va::Abstractions.VertexArray, transform::Mat4f0 = Mat4f0(I),
)
    shader |> Backend.bind
    Backend.upload_uniform(shader, "u_ViewProjection", State.view_projection)
    Backend.upload_uniform(shader, "u_Model", transform)

    va |> Backend.bind
    va |> Backend.draw_indexed
end


end
