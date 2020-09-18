struct Context <: Abstractions.AbstractContext
    window_handle::GLFW.Window
end

function init(context::Context)
    GLFW.MakeContextCurrent(context.window_handle)
    @info """
    OpenGL Info:
        - version: $(glGetString(GL_VERSION) |> unsafe_string)
        - vendor: $(glGetString(GL_VENDOR) |> unsafe_string)
        - renderer: $(glGetString(GL_RENDERER) |> unsafe_string)
    """
end

function swap_buffers(context::Context)
    GLFW.SwapBuffers(context.window_handle)
end
