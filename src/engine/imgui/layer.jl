struct ImGuiLayer <: EngineCore.Layer end

function EngineCore.on_attach(iml::ImGuiLayer)
    @info "Attaching ImGui Layer"
    CImGui.CreateContext()
    CImGui.StyleColorsDark()

    io = CImGui.GetIO()
    io.BackendFlags |= CImGui.ImGuiBackendFlags_HasMouseCursors
    io.BackendFlags |= CImGui.ImGuiBackendFlags_HasSetMousePos
    io.BackendPlatformName = "imgui_impl_glfw"

    # keyboard mapping
    CImGui.Set_KeyMap(io, CImGui.ImGuiKey_Tab, GLFW.KEY_TAB)
    CImGui.Set_KeyMap(io, CImGui.ImGuiKey_LeftArrow, GLFW.KEY_LEFT)
    CImGui.Set_KeyMap(io, CImGui.ImGuiKey_RightArrow, GLFW.KEY_RIGHT)
    CImGui.Set_KeyMap(io, CImGui.ImGuiKey_UpArrow, GLFW.KEY_UP)
    CImGui.Set_KeyMap(io, CImGui.ImGuiKey_DownArrow, GLFW.KEY_DOWN)
    CImGui.Set_KeyMap(io, CImGui.ImGuiKey_PageUp, GLFW.KEY_PAGE_UP)
    CImGui.Set_KeyMap(io, CImGui.ImGuiKey_PageDown, GLFW.KEY_PAGE_DOWN)
    CImGui.Set_KeyMap(io, CImGui.ImGuiKey_Home, GLFW.KEY_HOME)
    CImGui.Set_KeyMap(io, CImGui.ImGuiKey_End, GLFW.KEY_END)
    CImGui.Set_KeyMap(io, CImGui.ImGuiKey_Insert, GLFW.KEY_INSERT)
    CImGui.Set_KeyMap(io, CImGui.ImGuiKey_Delete, GLFW.KEY_DELETE)
    CImGui.Set_KeyMap(io, CImGui.ImGuiKey_Backspace, GLFW.KEY_BACKSPACE)
    CImGui.Set_KeyMap(io, CImGui.ImGuiKey_Space, GLFW.KEY_SPACE)
    CImGui.Set_KeyMap(io, CImGui.ImGuiKey_Enter, GLFW.KEY_ENTER)
    CImGui.Set_KeyMap(io, CImGui.ImGuiKey_Escape, GLFW.KEY_ESCAPE)
    CImGui.Set_KeyMap(io, CImGui.ImGuiKey_A, GLFW.KEY_A)
    CImGui.Set_KeyMap(io, CImGui.ImGuiKey_C, GLFW.KEY_C)
    CImGui.Set_KeyMap(io, CImGui.ImGuiKey_V, GLFW.KEY_V)
    CImGui.Set_KeyMap(io, CImGui.ImGuiKey_X, GLFW.KEY_X)
    CImGui.Set_KeyMap(io, CImGui.ImGuiKey_Y, GLFW.KEY_Y)
    CImGui.Set_KeyMap(io, CImGui.ImGuiKey_Z, GLFW.KEY_Z)

    CImGui.ImGui_ImplGlfw_InitForOpenGL(Ray.native_window(Ray.get_application()), true)
    CImGui.ImGui_ImplOpenGL3_Init(410)
end

function EngineCore.on_detach(iml::ImGuiLayer)

end

show = true

function EngineCore.on_update(iml::ImGuiLayer, timestep::Float64)
    global show
    io = CImGui.GetIO()
    io.DeltaTime = timestep

    @c CImGui.ShowDemoWindow(&show)
end

function EngineCore.on_event(iml::ImGuiLayer, ::Event.AbstractEvent)

end

function on_begin()
    CImGui.ImGui_ImplOpenGL3_NewFrame()
    CImGui.ImGui_ImplGlfw_NewFrame()
    CImGui.NewFrame()
end

function on_end()
    io = CImGui.GetIO()
    window = Ray.get_application().window
    io.DisplaySize = CImGui.ImVec2(window |> get_width, window |> get_height)

    CImGui.Render()
    CImGui.ImGui_ImplOpenGL3_RenderDrawData(CImGui.GetDrawData())
end
