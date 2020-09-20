mutable struct VertexArray <: Abstractions.VertexArray
    id::UInt32
    index_buffer::Union{IndexBuffer, Nothing}
    vertex_buffers::Vector{VertexBuffer}
    vertex_buffer_id::Int32

    function VertexArray()
        id = @ref glGenVertexArrays(1, RepUInt32)
        new(id, nothing, [], 0)
    end
end

bind(va::VertexArray) = glBindVertexArray(va.id)
unbind(::VertexArray) = glBindVertexArray(0)
delete(va::VertexArray) = glDeleteVertexArrays(1, Ref(va.id))

function add_vertex_buffer(va::VertexArray, vb::VertexBuffer)
    glBindVertexArray(va.id)
    bind(vb)
    for element in vb.layout.elements
        _set_pointer!(va, vb.layout, element, element.type)
    end
    glBindVertexArray(0)
end

function _set_pointer!(
    va::VertexArray, layout::BufferLayout, element::BufferElement, ::Any,
)
    glEnableVertexAttribArray(va.vertex_buffer_id)
    glVertexAttribPointer(
        va.vertex_buffer_id,
        length(element),
        get_base_type(element),
        element.normalized ? GL_TRUE : GL_FALSE,
        layout.stride,
        Ptr{Cvoid}(Int64(element.offset))
    )
    va.vertex_buffer_id += 1
end

function _set_pointer!(
    va::VertexArray, layout::BufferLayout, element::BufferElement, type::Mat,
)
    _get_count(::Mat4) = 4
    _get_count(::Mat3) = 3
    count = _get_count(type)

    for i in 0:count - 1
        glEnableVertexAttribArray(va.vertex_buffer_id)
        glVertexAttribPointer(
            va.vertex_buffer_id,
            length(element),
            get_base_type(element),
            element.normalized ? GL_TRUE : GL_FALSE,
            layout.stride,
            Ptr{Cvoid}(Int64(element.offset + sizeof(eltype(type)) * count * i))
        )
        va.vertex_buffer_id += 1
    end
end

function set_index_buffer(va::VertexArray, ib::IndexBuffer)
    glBindVertexArray(va.id)
    ib |> bind
    va.index_buffer = ib
    glBindVertexArray(0)
end

get_base_type(element::BufferElement) =
    element.type |> eltype |> _get_opengl_base_type

_get_opengl_base_type(::Type{T}) where T <: Integer = GL_INT
_get_opengl_base_type(::Type{T}) where T <: Real = GL_FLOAT
_get_opengl_base_type(::Type{Bool}) = GL_BOOL
