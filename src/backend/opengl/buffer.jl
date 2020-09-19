mutable struct VertexBuffer <: Abstractions.VertexBuffer
    id::UInt32
    layout::Union{Abstractions.BufferLayout, Nothing}
end

function VertexBuffer(
    data::Union{AbstractArray, Ptr{Nothing}}, size::Integer,
)
    id = @ref glGenBuffers(1, RepUInt32)
    type = data == C_NULL ? GL_DYNAMIC_DRAW : GL_STATIC_DRAW

    glBindBuffer(GL_ARRAY_BUFFER, id)
    glBufferData(GL_ARRAY_BUFFER, size, data, type)
    glBindBuffer(GL_ARRAY_BUFFER, 0)

    VertexBuffer(id, nothing)
end

VertexBuffer(size::Integer) = VertexBuffer(C_NULL, size)

bind(buffer::VertexBuffer) = glBindBuffer(GL_ARRAY_BUFFER, buffer.id)
unbind(::VertexBuffer) = glBindBuffer(GL_ARRAY_BUFFER, 0)
set_layout(buffer::VertexBuffer, layout::Abstractions.BufferLayout) =
    buffer.layout = layout


struct IndexBuffer <: Abstractions.IndexBuffer
    id::UInt32
    count::UInt32
end

function IndexBuffer(
    indices::AbstractArray, count::Union{Integer, Nothing} = nothing,
)
    id = @ref glGenBuffers(1, RepUInt32)
    count = count ≡ nothing ? length(indices) : count

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, id)
    glBufferData(
        GL_ELEMENT_ARRAY_BUFFER, sizeof(eltype(indices)) * count,
        indices, GL_STATIC_DRAW)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)

    IndexBuffer(id, count)
end

bind(buffer::IndexBuffer) = glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer.id)
unbind(::IndexBuffer) = glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)

get_base_type(element::BufferElement) =
    element.type |> eltype |> _get_opengl_base_type

_get_opengl_base_type(::Type{T}) where T <: Integer = GL_INT
_get_opengl_base_type(::Type{T}) where T <: Real = GL_FLOAT
_get_opengl_base_type(::Type{Bool}) = GL_BOOL
