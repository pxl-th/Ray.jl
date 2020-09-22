clear() = glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
set_clear_color(color::Point4f0) = glClearColor(color...)
set_clear_color(r, g, b, a) = glClearColor(r, g, b, a)

function init()
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
