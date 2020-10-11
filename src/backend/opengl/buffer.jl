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
delete(buffer::VertexBuffer) = glDeleteBuffers(1, Ref(buffer.id))
set_layout(buffer::VertexBuffer, layout::Abstractions.BufferLayout) =
    buffer.layout = layout

function set_data!(vb::VertexBuffer, data::AbstractVector, size::Integer)
    glBindBuffer(GL_ARRAY_BUFFER, vb.id)
    glBufferSubData(GL_ARRAY_BUFFER, 0, size, data)
end

function get_data(vb::VertexBuffer, size::Integer, data::AbstractArray)
    glBindBuffer(GL_ARRAY_BUFFER, vb.id)
    glGetBufferSubData(GL_ARRAY_BUFFER, 0, size, data)
    data
end


struct IndexBuffer <: Abstractions.IndexBuffer
    id::UInt32
    count::UInt32
    primitive_type::UInt32
end

function IndexBuffer(
    indices::AbstractArray, count::Union{Integer, Nothing} = nothing;
    primitive_type::UInt32 = GL_TRIANGLES,
)
    id = @ref glGenBuffers(1, RepUInt32)
    count = count ≡ nothing ? length(indices) : count

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, id)
    glBufferData(
        GL_ELEMENT_ARRAY_BUFFER, sizeof(eltype(indices)) * count,
        indices, GL_STATIC_DRAW)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)

    IndexBuffer(id, count, primitive_type)
end

bind(buffer::IndexBuffer) = glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer.id)
unbind(::IndexBuffer) = glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)
delete(buffer::IndexBuffer) = glDeleteBuffers(1, Ref(buffer.id))
