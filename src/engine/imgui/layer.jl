abstract type GuiLayer <: Layer end
struct ImGuiLayer <: GuiLayer end

function EngineCore.on_attach(::GuiLayer)
    @info "Attaching ImGui Layer"
    CImGui.CreateContext()

    io = CImGui.GetIO()
    io.ConfigFlags |= CImGui.ImGuiConfigFlags_NavEnableKeyboard

    CImGui.StyleColorsDark()
    CImGui.ImGuiStyle_Set_WindowRounding(CImGui.GetStyle(), 0f0)

    CImGui.ImGui_ImplGlfw_InitForOpenGL(
        Ray.native_window(Ray.get_application()), false)
    CImGui.ImGui_ImplOpenGL3_Init(410)
end

function EngineCore.on_imgui_begin(::GuiLayer)
    CImGui.ImGui_ImplOpenGL3_NewFrame()
    CImGui.ImGui_ImplGlfw_NewFrame()
    CImGui.NewFrame()
end

function EngineCore.on_imgui_end(::GuiLayer)
    io = CImGui.GetIO()
    window = Ray.get_application().window
    io.DisplaySize = CImGui.ImVec2(window |> get_width, window |> get_height)

    CImGui.Render()
    CImGui.ImGui_ImplOpenGL3_RenderDrawData(CImGui.GetDrawData())
end

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

