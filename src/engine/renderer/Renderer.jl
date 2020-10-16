include("shader.jl")

mutable struct SceneData
    view_projection::Mat4f0
end

const State = SceneData(zeros(Mat4f0))

function begin_scene(camera::PerspectiveCamera)
    State.view_projection = camera.view_projection
end

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
