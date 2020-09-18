module Abstractions

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

end
