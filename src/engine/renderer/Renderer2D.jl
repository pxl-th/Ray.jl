module Renderer2D

using GeometryBasics
using LinearAlgebra
using StaticArrays
using Parameters: @with_kw
using GLFW

using Ray.Transformations
using Ray.Input
using Ray.Event
using Ray.OrthographicCameraModule

include("../../backend/Abstractions.jl")
include("../../backend/opengl/OpenGL.jl")

using .Abstractions
using .OpenGLBackend

const Backend = OpenGLBackend

@with_kw mutable struct Renderer2DData
    quad_vertex_array::Union{Backend.VertexArray, Nothing} = nothing
    quad_vertex_buffer::Union{Backend.VertexBuffer, Nothing} = nothing
    color_shader::Union{Backend.Shader, Nothing} = nothing
    texture_shader::Union{Backend.Shader, Nothing} = nothing
end

const Data = Renderer2DData()

function init()
    layout = BufferLayout([
        BufferElement(Point3f0, "a_Position"),
        BufferElement(Point2f0, "a_TexCoord"),
    ])
    data = Float32[
        -0.5, -0.5, 0.0, 0.0, 0.0,
         0.5, -0.5, 0.0, 1.0, 0.0,
         0.5,  0.5, 0.0, 1.0, 1.0,
        -0.5,  0.5, 0.0, 0.0, 1.0,
    ]
    indices = UInt32[0, 1, 2, 2, 3, 0]

    Data.quad_vertex_array = Backend.VertexArray()
    Data.quad_vertex_buffer = Backend.VertexBuffer(data, sizeof(data))
    ib = Backend.IndexBuffer(indices)

    Backend.set_layout(Data.quad_vertex_buffer, layout)
    Backend.add_vertex_buffer(Data.quad_vertex_array, Data.quad_vertex_buffer)
    Backend.set_index_buffer(Data.quad_vertex_array, ib)

    Data.color_shader = Backend.Shader(
        raw"C:\Users\tonys\projects\julia\Ray\assets\shaders\single_color.glsl",
    )
    Data.texture_shader = Backend.Shader(
        raw"C:\Users\tonys\projects\julia\Ray\assets\shaders\texture.glsl",
    )
    Data.texture_shader |> Backend.bind
    Backend.upload_uniform(Data.texture_shader, "u_Texture", 0)
end

function shutdown() end

function begin_scene(camera::OrthographicCamera)
    Data.color_shader |> Backend.bind
    Backend.upload_uniform(
        Data.color_shader, "u_ViewProjection", camera.view_projection,
    )
    Data.texture_shader |> Backend.bind
    Backend.upload_uniform(
        Data.texture_shader, "u_ViewProjection", camera.view_projection,
    )
end

function end_scene() end

draw_quad(position::Vec2f0, size::Vec2f0, color::Vec4f0) =
    draw_quad(Vec3f0(position[1], position[2], 0f0), size, color)

function draw_quad(position::Vec3f0, size::Vec2f0, color::Vec4f0)
    Data.color_shader |> Backend.bind
    Backend.upload_uniform(Data.color_shader, "u_Color", color)

    transformation = translation(position) * scaling(size[1], size[2], 1f0)
    Backend.upload_uniform(Data.color_shader, "u_Transform", transformation)

    Data.quad_vertex_array |> Backend.bind
    Backend.draw_indexed(Data.quad_vertex_array)
end

draw_quad(position::Vec2f0, size::Vec2f0, texture::Backend.Texture2D) =
    draw_quad(Vec3f0(position[1], position[2], 0f0), size, texture)

function draw_quad(position::Vec3f0, size::Vec2f0, texture::Backend.Texture2D)
    Data.texture_shader |> Backend.bind
    texture |> Backend.bind

    transformation = translation(position) * scaling(size[1], size[2], 1f0)
    Backend.upload_uniform(Data.texture_shader, "u_Transform", transformation)

    Data.quad_vertex_array |> Backend.bind
    Backend.draw_indexed(Data.quad_vertex_array)
end

end
