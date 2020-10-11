function uv_sphere(steps = 32, scale = 1f0)
    data = Float32[]
    position = Point3f0(0f0, 1f0, 0f0) * scale
    append!(data, position)
    append!(data, Point2f0(0f0, 0f0))
    append!(data, position)

    num_vertices = 0
    for j in 0:(steps - 2)
        polar = π * (j + 1) / steps
        sp = sin(polar)
        cp = cos(polar)
        for i in 0:(steps - 1)
            azimuth = 2f0 * π * i / steps
            sa = sin(azimuth)
            ca = cos(azimuth)

            position = Point3f0(sp * ca, cp, sp * sa) * scale
            uv = Point2f0(i / steps, j / steps)
            append!(data, position)
            append!(data, uv)
            append!(data, position)

            num_vertices += 1
        end
    end
    position = Point3f0(0f0, -1f0, 0f0) * scale
    append!(data, position)
    append!(data, Point2f0(0f0, 0f0))
    append!(data, position)

    indices = UInt32[]
    for i in 0:(steps - 1)
        a = i + 1
        b = (i + 1) % steps + 1
        append!(indices, Point3f0(0, b, a))
    end

    for j in 0:(steps - 3)
        a_start = j * steps + 1
        b_start = (j + 1) * steps + 1
        for i in 0:(steps - 1)
            a = a_start + i
            a1 = a_start + (i + 1) % steps
            b = b_start + i
            b1 = b_start + (i + 1) % steps
            append!(indices, Point3f0(a, a1, b))
            append!(indices, Point3f0(b, a1, b1))
        end
    end

    for i in 0:(steps - 1)
        a = i + steps * (steps - 2) + 1
        b = (i + 1) % steps + steps * (steps - 2) + 1
        append!(indices, Point3f0(num_vertices - 1, a, b))
    end

    va = Ray.Backend.VertexArray()
    vb = Ray.Backend.VertexBuffer(data, sizeof(data))
    ib = Ray.Backend.IndexBuffer(indices)

    Ray.Backend.set_layout(vb, Ray.Renderer.BufferLayout([
        Ray.Renderer.BufferElement(Point3f0, "a_Position"),
        Ray.Renderer.BufferElement(Point2f0, "a_TexCoord"),
        Ray.Renderer.BufferElement(Vec3f0, "a_Normal"),
    ]))
    Ray.Backend.add_vertex_buffer(va, vb)
    Ray.Backend.set_index_buffer(va, ib)

    va
end

function get_screen_plane()
    data = Float32[
        -1,-1, 0, 0,
         1,-1, 1, 0,
         1, 1, 1, 1,
        -1, 1, 0, 1,
    ]
    indices = UInt32[0, 1, 2, 2, 3, 0]

    va = Ray.Backend.VertexArray()
    vb = Ray.Backend.VertexBuffer(data, sizeof(data))
    ib = Ray.Backend.IndexBuffer(indices)

    Ray.Backend.set_layout(vb, Ray.Renderer.BufferLayout([
        Ray.Renderer.BufferElement(Point2f0, "a_Position"),
        Ray.Renderer.BufferElement(Point2f0, "a_TexCoord"),
    ]))
    Ray.Backend.add_vertex_buffer(va, vb)
    Ray.Backend.set_index_buffer(va, ib)

    va
end

function get_cubebox()
    data = Float32[
         1,  1, -1,
         1, -1, -1,
         1,  1,  1,
         1, -1,  1,
        -1,  1, -1,
        -1, -1, -1,
        -1,  1,  1,
        -1, -1,  1,
    ]
    indices = UInt32[
        0, 4, 6, 2,
        3, 2, 6, 7,
        7, 6, 4, 5,
        5, 1, 3, 7,
        1, 0, 2, 3,
        5, 4, 0, 1,
    ]

    va = Ray.Backend.VertexArray()
    vb = Ray.Backend.VertexBuffer(data, sizeof(data))
    ib = Ray.Backend.IndexBuffer(indices, primitive_type=GL_QUADS)

    Ray.Backend.set_layout(vb, Ray.Renderer.BufferLayout([
        Ray.Renderer.BufferElement(Point3f0, "a_Position"),
    ]))
    Ray.Backend.add_vertex_buffer(va, vb)
    Ray.Backend.set_index_buffer(va, ib)

    va
end
