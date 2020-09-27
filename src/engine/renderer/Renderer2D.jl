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

struct QuadVertex
    position::Vec3f0
    color::Vec4f0
    texture_coordinate::Vec2f0
end

@with_kw mutable struct Renderer2DData
    max_quads::UInt32 = 10000
    max_vertices::UInt32 = max_quads * 4
    max_indices::UInt32 = max_quads * 6

    quad_vertex_array::Union{Backend.VertexArray, Nothing} = nothing
    quad_vertex_buffer::Union{Backend.VertexBuffer, Nothing} = nothing
    texture_shader::Union{Backend.Shader, Nothing} = nothing
    white_texture::Union{Backend.Texture2D, Nothing} = nothing

    quad_vertex_buffer_base::Union{Vector{QuadVertex}, Nothing} = nothing
    quad_count::UInt32 = 0
    quad_vertex_count::UInt32 = 0

    quad_vertex_positions::Union{Vector{Point4f0}, Nothing} = nothing
    quad_index_count::UInt32 = 0
end

const Data = Renderer2DData()

function init()
    Data.quad_vertex_buffer_base = Vector{QuadVertex}(undef, Data.max_quads)
    quad_indices = Vector{UInt32}(undef, Data.max_indices)
    offset = 0
    for i in 1:6:Data.max_indices
        quad_indices[i] = offset + 0
        quad_indices[i + 1] = offset + 1
        quad_indices[i + 2] = offset + 2

        quad_indices[i + 3] = offset + 2
        quad_indices[i + 4] = offset + 3
        quad_indices[i + 5] = offset + 0

        offset += 6
    end

    Data.quad_vertex_positions = Vector{Point4f0}(undef, 4)
    Data.quad_vertex_positions[1] = Point4f0(-0.5f0, -0.5f0, 0.0f0, 1.0f0)
    Data.quad_vertex_positions[2] = Point4f0(0.5f0, -0.5f0, 0.0f0, 1.0f0)
    Data.quad_vertex_positions[3] = Point4f0(0.5f0,  0.5f0, 0.0f0, 1.0f0)
    Data.quad_vertex_positions[4] = Point4f0(-0.5f0,  0.5f0, 0.0f0, 1.0f0)

    Data.quad_vertex_array = Backend.VertexArray()
    Data.quad_vertex_buffer = Backend.VertexBuffer(Data.max_quads * sizeof(QuadVertex))
    ib = Backend.IndexBuffer(quad_indices)

    Backend.set_layout(Data.quad_vertex_buffer, BufferLayout([
        BufferElement(Point3f0, "a_Position"),
        BufferElement(Point4f0, "a_Color"),
        BufferElement(Point2f0, "a_TexCoord"),
    ]))
    Backend.add_vertex_buffer(Data.quad_vertex_array, Data.quad_vertex_buffer)
    Backend.set_index_buffer(Data.quad_vertex_array, ib)

    Data.texture_shader = Backend.Shader(
        raw"C:\Users\tonys\projects\julia\Ray\assets\shaders\texture.glsl",
    )
    Data.texture_shader |> Backend.bind
    Backend.upload_uniform(Data.texture_shader, "u_Texture", 0)

    Data.white_texture = Backend.Texture2D(1, 1)
    Backend.set_data!(Data.white_texture, UInt8[0xff, 0xff, 0xff, 0xff], 4)
end

function shutdown() end

function begin_scene(camera::OrthographicCamera)
    Data.texture_shader |> Backend.bind
    Backend.upload_uniform(
        Data.texture_shader, "u_ViewProjection", camera.view_projection,
    )

    Data.quad_index_count = 0
    Data.quad_count = 0
    Data.quad_vertex_count = 0
end

function begin_scene(camera::OrthographicCamera, transformation::Mat4f0)
    view_projection = camera.view_projection * inv(transformation)

    Data.texture_shader |> Backend.bind
    Backend.upload_uniform(
        Data.texture_shader, "u_ViewProjection", view_projection,
    )

    Data.quad_index_count = 0
    Data.quad_count = 0
    Data.quad_vertex_count = 0
end

function end_scene()
    Data.quad_count == 0 && return

    Backend.set_data!(
        Data.quad_vertex_buffer,
        Data.quad_vertex_buffer_base,
        sizeof(QuadVertex) * Data.quad_vertex_count,
    )
    flush()
end

function flush()
    Data.quad_count == 0 && return

    Data.white_texture |> Backend.bind
    Data.quad_vertex_array |> Backend.bind
    Backend.draw_indexed(Data.quad_vertex_array, Data.quad_index_count)
end

function flush_reset()
    end_scene()
    Data.quad_count = 0
end


# Textured quads.

draw_quad(position::Vec2f0, size::Vec2f0, texture::Backend.Texture2D) =
    draw_quad(Vec3f0(position[1], position[2], 0f0), size, texture)

function draw_quad(position::Vec3f0, size::Vec2f0, texture::Backend.Texture2D)
    transformation = translation(position[1], position[2], position[3]) *
        scaling(size[1], size[2], 1f0)
    draw_quad(transformation, texture)
end

function draw_quad(transform::Mat4f0, texture::Backend.Texture2D)
    quad_vertex_count = 4
    texture_coordinates = Point2f0[
        Point2f0(0f0, 0f0), Point2f0(1f0, 0f0),
        Point2f0(1f0, 1f0), Point2f0(0f0, 1f0),
    ]

    Data.quad_index_count >= Data.max_indices && flush_reset()

    Data.quad_count += 1
    Data.quad_index_count += 6
    for i in 1:quad_vertex_count
        Data.quad_vertex_count += 1
        Data.quad_vertex_buffer_base[Data.quad_vertex_count] = QuadVertex(
            Point3f0(transform * Data.quad_vertex_positions[i]),
            Point4f0(1, 1, 1, 1),
            texture_coordinates[i],
        )
    end
end

end
