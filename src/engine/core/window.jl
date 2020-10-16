@with_kw mutable struct WindowProps
    title::String = "Window"
    width::Int64 = 1280
    height::Int64 = 720

    vsync::Bool = true
end

mutable struct Window
    properties::WindowProps
    window::GLFW.Window
    context::Ray.Backend.Context
end

function Window(props::WindowProps)
    @info "Creating window $(props.title) ($(props.width), $(props.height))"

    global GLFW_INITIALIZED
    if !GLFW_INITIALIZED
        success = GLFW.Init()
        @assert success "Failed to initialize GLFW!"
        GLFW_INITIALIZED = true
        GLFW.SetErrorCallback((error, description) ->
            @error "Error $error: $description")
    end

    window = GLFW.CreateWindow(props.width, props.height, props.title)
    context = Ray.Backend.Context(window)
    context |> Ray.Backend.init

    Window(props, window, context)
end

function set_callbacks(window::Window, callback_handle::Function)
    application = Ray.get_application()

    GLFW.SetWindowCloseCallback(window.window, ::GLFW.Window ->
        callback_handle(application, Event.WindowClose(false)))
    GLFW.SetWindowSizeCallback(window.window, (_, width, height) ->
        callback_handle(application, Event.WindowResize(false, width, height)))
    GLFW.SetCursorPosCallback(window.window,
        (::GLFW.Window, x_pos::Float64, y_pos::Float64) ->
            callback_handle(application, Event.MouseMoved(false, x_pos, y_pos)))
    GLFW.SetCharCallback(window.window, (::GLFW.Window, key::Char) ->
        callback_handle(application, Event.KeyTyped(false, key)))
    GLFW.SetScrollCallback(window.window,
        (::GLFW.Window, x_offset::Float64, y_offset::Float64) ->
            callback_handle(application, Event.MouseScrolled(false, x_offset, y_offset)))

    GLFW.SetKeyCallback(window.window,
        (::GLFW.Window, key::GLFW.Key, ::Int32, action::GLFW.Action, ::Int32) -> begin
            if action == GLFW.PRESS
                event = Event.KeyPressed(false, key, 0)
            elseif action == GLFW.RELEASE
                event = Event.KeyReleased(false, key)
            elseif action == GLFW.REPEAT
                event = Event.KeyPressed(false, key, 1)
            end
            callback_handle(application, event)
        end)
    GLFW.SetMouseButtonCallback(window.window,
        (::GLFW.Window, button::GLFW.MouseButton, action::GLFW.Action, ::Int32) -> begin
            if action == GLFW.PRESS
                event = Event.MouseButtonPressed(false, button)
            elseif action == GLFW.RELEASE
                event = Event.MouseButtonReleased(false, button)
            end
            callback_handle(application, event)
        end)
end

function set_vsync(window::Window, enabled::Bool)
    window.properties.vsync = enabled
    enabled ? GLFW.SwapInterval(1) : GLFW.SwapInterval(0)
end

is_vsync(window::Window)::Bool = window.properties.vsync
get_width(window::Window)::Int64 = window.properties.width
get_height(window::Window)::Int64 = window.properties.height
set_width(window::Window, width::Int64) = window.properties.width = width
set_height(window::Window, height::Int64) = window.properties.height = height

function on_update(window::Window)
    GLFW.PollEvents()
    window.context |> Ray.Backend.swap_buffers
end
