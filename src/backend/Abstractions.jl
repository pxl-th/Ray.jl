module Abstractions
export BufferLayout, BufferElement, size, length

abstract type AbstractContext end

function init(::AbstractContext) end
function swap_buffers(::AbstractContext) end

abstract type VertexBuffer end

function bind(::VertexBuffer) end
function unbind(::VertexBuffer) end
function delete(::VertexBuffer) end

abstract type IndexBuffer end

function bind(::IndexBuffer) end
function unbind(::IndexBuffer) end
function delete(::IndexBuffer) end

abstract type VertexArray end

function bind(::VertexArray) end
function unbind(::VertexArray) end
function delete(::VertexArray) end
function add_vertex_buffer(::VertexArray, ::VertexBuffer) end
function set_index_buffer(::VertexArray, ::IndexBuffer) end

abstract type Shader end

function bind(::Shader) end
function unbind(::Shader) end
function delete(::Shader) end

mutable struct BufferElement
    name::String
    type::DataType # TODO constrain to geometry basics
    offset::UInt32
    normalized::Bool
end

BufferElement(type::DataType, name::String, normalized::Bool = false) =
    BufferElement(name, type, 0, normalized)

size(be::BufferElement) = sizeof(be.type)
Base.length(be::BufferElement) = length(be.type)

struct BufferLayout
    elements::Vector{BufferElement}
    stride::UInt32
end

function BufferLayout(elements::Vector{BufferElement})
    stride = _calculate_stride_and_offset!(elements)
    BufferLayout(elements, stride)
end

function _calculate_stride_and_offset!(
    elements::AbstractVector{BufferElement},
)::UInt32
    offset = 0
    stride = 0

    for element in elements
        element.offset += offset
        offset += size(element)
        stride += size(element)
    end
    UInt32(stride)
end

end
