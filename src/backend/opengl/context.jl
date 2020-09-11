struct Context <: Abstractions.AbstractContext
    window_handle::GLFW.Window
end

function init(context::Context)
    GLFW.MakeContextCurrent(context.window_handle)
end

function swap_buffers(context::Context)
    GLFW.SwapBuffers(context.window_handle)
end
