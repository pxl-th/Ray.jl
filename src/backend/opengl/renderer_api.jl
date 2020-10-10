clear(bit::UInt32 = GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT) = glClear(bit)
set_clear_color(color::Point4f0) = glClearColor(color...)
set_clear_color(r, g, b, a) = glClearColor(r, g, b, a)

enable_depth() = glEnable(GL_DEPTH_TEST)
disable_depth() = glDisable(GL_DEPTH_TEST)

enable_wireframe() = glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)
disable_wireframe() = glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)

hide_cursor() = GLFW.SetInputMode(window, GLFW.CURSOR, GLFW.CURSOR_DISABLED)
show_cursor() = GLFW.SetInputMode(window, GLFW.CURSOR, GLFW.CURSOR_NORMAL)

set_viewport(width::Integer, height::Integer) = glViewport(0, 0, width, height)

function init(window)
    GLFW.SetInputMode(window, GLFW.CURSOR, GLFW.CURSOR_DISABLED)

    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

    glEnable(GL_DEPTH_TEST)
end

function draw_indexed(
    va::VertexArray, index_count::Union{UInt32, Nothing} = nothing,
)
    count = index_count ≡ nothing ? va.index_buffer.count : index_count
    glDrawElements(GL_TRIANGLES, count, GL_UNSIGNED_INT, C_NULL)
end
