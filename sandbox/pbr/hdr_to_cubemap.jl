function hdr_to_cubemap(irradiance_map::Ray.Backend.Texture2D)
    cubemap_width, cubemap_height = 512, 512
    cubemap = Ray.Backend.Cubemap(
        cubemap_width, cubemap_height,
        internal_format=GL_RGB16F, data_format=GL_RGB, type=GL_UNSIGNED_SHORT,
        min_filter=GL_LINEAR_MIPMAP_LINEAR,
    )
    depth_attachment = Ray.Backend.Texture2D(
        cubemap_width, cubemap_height, GL_UNSIGNED_INT,
        internal_format=GL_DEPTH_COMPONENT24, data_format=GL_DEPTH_COMPONENT,
    )
    fb = Ray.Backend.Framebuffer(Dict(
        GL_DEPTH_ATTACHMENT => Ray.Backend.Attachment(GL_TEXTURE_2D, 0, depth_attachment),
    ))

    mapping_shader = Ray.Backend.Shader(
        raw"C:\Users\tonys\projects\julia\Ray\assets\shaders\from-rectangle-to-cubemap.glsl",
    )
    convolution_shader = Ray.Backend.Shader(
        raw"C:\Users\tonys\projects\julia\Ray\assets\shaders\cubemap-convolution.glsl",
    )
    cubebox = get_cubebox()

    projection = Ray.Transformations.perspective(90f0, 1f0, 0.1f0, 10f0)
    views = [
        Ray.Transformations.look_at(Point3f0(0, 0, 0), Point3f0( 1,  0,  0), Point3f0(0, -1,  0)),
        Ray.Transformations.look_at(Point3f0(0, 0, 0), Point3f0(-1,  0,  0), Point3f0(0, -1,  0)),
        Ray.Transformations.look_at(Point3f0(0, 0, 0), Point3f0( 0,  1,  0), Point3f0(0,  0,  1)),
        Ray.Transformations.look_at(Point3f0(0, 0, 0), Point3f0( 0, -1,  0), Point3f0(0,  0, -1)),
        Ray.Transformations.look_at(Point3f0(0, 0, 0), Point3f0( 0,  0,  1), Point3f0(0, -1,  0)),
        Ray.Transformations.look_at(Point3f0(0, 0, 0), Point3f0( 0,  0, -1), Point3f0(0, -1,  0)),
    ]

    # Map environment map to cubemap.

    fb |> Ray.Backend.bind
    Ray.Backend.set_clear_color(0, 0, 0, 1)
    Ray.Backend.set_viewport(cubemap_width, cubemap_height)
    Ray.Backend.enable_depth()

    cubebox |> Ray.Backend.bind
    mapping_shader |> Ray.Backend.bind
    irradiance_map |> Ray.Backend.bind
    Ray.Backend.upload_uniform(mapping_shader, "u_EquirectangularMap", 0)

    for (i, view) in enumerate(views)
        color_attachment = Ray.Backend.Attachment(
            GL_TEXTURE_CUBE_MAP_POSITIVE_X + i - 1, UInt32(0), cubemap,
        )
        Ray.Backend.attach!(fb, GL_COLOR_ATTACHMENT0, color_attachment)
        Ray.Backend.upload_uniform(
            mapping_shader, "u_ViewProjection", projection * view,
        )

        Ray.Backend.clear()
        cubebox |> Ray.Backend.draw_indexed
    end
    fb |> Ray.Backend.unbind

    # Compute convolution.
    convolution_cubemap = Ray.Backend.Cubemap(
        32, 32,
        internal_format=GL_RGB16F, data_format=GL_RGB, type=GL_UNSIGNED_SHORT,
    )
    convolution_depth_attachment = Ray.Backend.Texture2D(
        32, 32, GL_UNSIGNED_INT,
        internal_format=GL_DEPTH_COMPONENT24, data_format=GL_DEPTH_COMPONENT,
    )

    conv_fb = Ray.Backend.Framebuffer()
    conv_fb |> Ray.Backend.bind

    Ray.Backend.set_clear_color(0, 0, 0, 1)
    Ray.Backend.set_viewport(32, 32)
    Ray.Backend.enable_depth()

    cubebox |> Ray.Backend.bind
    convolution_shader |> Ray.Backend.bind
    cubemap |> Ray.Backend.bind
    cubemap |> Ray.Backend.generate_mips
    Ray.Backend.upload_uniform(convolution_shader, "u_EnvironmentMap", 0)

    # TODO delete previous attachments
    Ray.Backend.attach!(conv_fb, GL_DEPTH_ATTACHMENT, Ray.Backend.Attachment(
        GL_TEXTURE_2D, 0, convolution_depth_attachment,
    ))
    for (i, view) in enumerate(views)
        color_attachment = Ray.Backend.Attachment(
            GL_TEXTURE_CUBE_MAP_POSITIVE_X + i - 1, 0, convolution_cubemap,
        )
        Ray.Backend.attach!(conv_fb, GL_COLOR_ATTACHMENT0, color_attachment)
        Ray.Backend.upload_uniform(
            convolution_shader, "u_ViewProjection", projection * view,
        )

        Ray.Backend.clear()
        cubebox |> Ray.Backend.draw_indexed
    end
    conv_fb |> Ray.Backend.bind

    cubebox |> Ray.Backend.delete
    mapping_shader |> Ray.Backend.delete
    convolution_shader |> Ray.Backend.delete

    depth_attachment |> Ray.Backend.delete
    convolution_depth_attachment |> Ray.Backend.delete

    # TODO: delete framebuffer w/ attachments
    cubemap, convolution_cubemap
end
