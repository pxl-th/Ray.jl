struct ImGuiLayer <: EngineCore.Layer end

function EngineCore.on_attach(iml::ImGuiLayer)
    @info "Attaching ImGui Layer"
    CImGui.CreateContext()

    io = CImGui.GetIO()
    io.ConfigFlags |= CImGui.ImGuiConfigFlags_NavEnableKeyboard

    CImGui.StyleColorsDark()

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
