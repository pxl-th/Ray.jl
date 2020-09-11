module Abstractions

abstract type AbstractContext end

function init(::AbstractContext) end
function swap_buffers(::AbstractContext) end

end
