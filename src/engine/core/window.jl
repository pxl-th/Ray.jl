@with_kw mutable struct WindowProps
    title::String = "Window"
    width::Int64 = 1024
    height::Int64 = 1024

    vsync::Bool = true
end

mutable struct Window
    properties::WindowProps
    window::GLFW.Window
    context::OpenGLBackend.Context
end

function Window(props::WindowProps)
    @info "Creating window $(props.title) ($(props.width), $(props.height))"

    global GLFW_INITIALIZED
    if !GLFW_INITIALIZED
        success = GLFW.Init()
        @assert success "Failed to initialize GLFW!"
        GLFW_INITIALIZED = true
    end

    window = GLFW.CreateWindow(props.width, props.height, props.title)
    context = OpenGLBackend.Context(window)
    context |> OpenGLBackend.init

    Window(props, window, context)
end

function set_callbacks(window::Window, callback_handle::Tuple)
    GLFW.SetWindowCloseCallback(window.window, w -> (
        callback_handle[1](callback_handle[2], Event.WindowClose(false))))
    GLFW.SetWindowSizeCallback(window.window, (window, width, height) -> (
        callback_handle[1](callback_handle[2],
            Event.WindowResize(false, width, height))))
end

function set_vsync(window::Window, enabled::Bool)
    window.properties.vsync = enabled
    enabled ? GLFW.SwapInterval(1) : GLFW.SwapInterval(0)
end

is_vsync(window::Window)::Bool = window.properties.vsync
get_width(window::Window)::Int64 = window.properties.width
get_height(window::Window)::Int64 = window.properties.height

function on_update(window::Window)
    GLFW.PollEvents()
    window.context |> OpenGLBackend.swap_buffers
end
