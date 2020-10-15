function integrate_brdf(width::Integer = 512, height::Integer = 512)
    brdf_lut = Ray.Backend.Texture2D(
        width, height, GL_UNSIGNED_SHORT,
        internal_format=GL_RGBA16F, data_format=GL_RGBA,
        wrap_s=GL_CLAMP_TO_EDGE, wrap_t=GL_CLAMP_TO_EDGE,
    )
    depth = Ray.Backend.Texture2D(
        width, height, GL_UNSIGNED_INT,
        internal_format=GL_DEPTH_COMPONENT24, data_format=GL_DEPTH_COMPONENT,
    )
    shader = Ray.Backend.Shader(raw"C:\Users\tonys\projects\julia\Ray\assets\shaders\precompute-brdf.glsl")
    screen = get_screen_plane()

    fb = Ray.Backend.Framebuffer(Dict(
        GL_COLOR_ATTACHMENT0 => Ray.Backend.Attachment(GL_TEXTURE_2D, 0, brdf_lut),
        GL_DEPTH_ATTACHMENT => Ray.Backend.Attachment(GL_TEXTURE_2D, 0, depth),
    ))
    fb |> Ray.Backend.bind
    shader |> Ray.Backend.bind

    Ray.Backend.set_viewport(width, height)
    Ray.Backend.set_clear_color(0, 0, 0, 1)
    Ray.Backend.enable_depth()
    Ray.Backend.clear()

    screen |> Ray.Backend.bind
    screen |> Ray.Backend.draw_indexed

    fb |> Ray.Backend.unbind

    shader |> Ray.Backend.delete
    depth |> Ray.Backend.delete
    screen |> Ray.Backend.delete

    brdf_lut
end
