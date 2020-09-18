struct ImGuiLayer <: EngineCore.Layer end

function EngineCore.on_attach(::ImGuiLayer)
    @info "Attaching ImGui Layer"
    CImGui.CreateContext()

    io = CImGui.GetIO()
    io.ConfigFlags |= CImGui.ImGuiConfigFlags_NavEnableKeyboard

    CImGui.StyleColorsDark()

    CImGui.ImGui_ImplGlfw_InitForOpenGL(
        Ray.native_window(Ray.get_application()), false)
    CImGui.ImGui_ImplOpenGL3_Init(410)
end

function EngineCore.on_detach(::ImGuiLayer) end
function EngineCore.on_update(::ImGuiLayer, timestep::Float64) end
function EngineCore.on_event(::ImGuiLayer, ::Event.AbstractEvent) end

# Passthrough to default callbacks.
EngineCore.on_event(::ImGuiLayer, event::Event.KeyPressed) =
    CImGui.GLFWBackend.ImGui_ImplGlfw_KeyCallback(
        Ray.native_window(Ray.get_application()), event.key, 0, GLFW.PRESS, 0)
EngineCore.on_event(::ImGuiLayer, event::Event.KeyReleased) =
    CImGui.GLFWBackend.ImGui_ImplGlfw_KeyCallback(
        Ray.native_window(Ray.get_application()), event.key, 0, GLFW.RELEASE, 0)
EngineCore.on_event(::ImGuiLayer, event::Event.KeyTyped) =
    CImGui.GLFWBackend.ImGui_ImplGlfw_CharCallback(
        Ray.native_window(Ray.get_application()), event.key)
EngineCore.on_event(::ImGuiLayer, event::Event.MouseScrolled) =
    CImGui.GLFWBackend.ImGui_ImplGlfw_ScrollCallback(
        Ray.native_window(Ray.get_application()), event.x_offset, event.y_offset)

function EngineCore.on_imgui_begin(::ImGuiLayer)
    CImGui.ImGui_ImplOpenGL3_NewFrame()
    CImGui.ImGui_ImplGlfw_NewFrame()
    CImGui.NewFrame()
end

function EngineCore.on_imgui_end(::ImGuiLayer)
    io = CImGui.GetIO()
    window = Ray.get_application().window
    io.DisplaySize = CImGui.ImVec2(window |> get_width, window |> get_height)

    CImGui.Render()
    CImGui.ImGui_ImplOpenGL3_RenderDrawData(CImGui.GetDrawData())
end

function EngineCore.on_imgui_render(::ImGuiLayer, timestep::Float64)
    show = true
    @c CImGui.ShowDemoWindow(&show)
end
