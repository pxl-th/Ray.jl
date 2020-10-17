struct PBRPrecompute
    environment::Ray.Backend.Cubemap
    irradiance::Ray.Backend.Cubemap
    prefiltered::Ray.Backend.Cubemap
    brdf_lut::Ray.Backend.Texture2D
end

function precompute_pbr(
    irradiance_map::Ray.Backend.Texture2D,
    cubemap_width::Integer = 512, cubemap_height::Integer = 512,
    conv_width::Integer = 32, conv_height::Integer = 32,
)
    cube = get_cubebox()
    pvs = _get_projection_views()

    fb = Ray.Backend.Framebuffer()
    fb |> Ray.Backend.bind
    cube |> Ray.Backend.bind

    Ray.Backend.set_clear_color(0, 0, 0, 1)
    Ray.Backend.enable_depth()

    environment_cubemap = _map_to_cubemap(fb, irradiance_map, cube, pvs)
    environment_convolution = _convolve(fb, environment_cubemap, cube, pvs)
    prefiltered_cubemap = _prefilter(fb, environment_cubemap, cube, pvs)
    brdf_lut = _integrate_brdf(fb)

    Ray.Backend.detach!(fb, GL_COLOR_ATTACHMENT0)
    fb |> Ray.Backend.unbind
    fb |> Ray.Backend.delete
    cube |> Ray.Backend.delete
    # TODO: delete framebuffer

    PBRPrecompute(
        environment_cubemap, environment_convolution,
        prefiltered_cubemap, brdf_lut,
   )
end

function _integrate_brdf(
    fb::Ray.Backend.Framebuffer, width::Integer = 512, height::Integer = 512,
)
    brdf_lut = Ray.Backend.Texture2D(
        width, height, GL_UNSIGNED_SHORT,
        internal_format=GL_RGBA16F, data_format=GL_RGBA,
        wrap_s=GL_CLAMP_TO_EDGE, wrap_t=GL_CLAMP_TO_EDGE,
    )
    depth = Ray.Backend.Texture2D(
        width, height, GL_UNSIGNED_INT,
        internal_format=GL_DEPTH_COMPONENT24, data_format=GL_DEPTH_COMPONENT,
    )
    shader = Ray.get_asset_shader("precompute-brdf")
    screen = get_screen_plane()

    Ray.Backend.attach!(
        fb, GL_DEPTH_ATTACHMENT, Ray.Backend.Attachment(GL_TEXTURE_2D, 0, depth),
    )
    Ray.Backend.attach!(
        fb, GL_COLOR_ATTACHMENT0, Ray.Backend.Attachment(GL_TEXTURE_2D, 0, brdf_lut),
    )

    Ray.Backend.set_viewport(width, height)
    Ray.Backend.clear()
    shader |> Ray.Backend.bind
    screen |> Ray.Backend.bind
    screen |> Ray.Backend.draw_indexed

    shader |> Ray.Backend.delete
    depth |> Ray.Backend.delete
    screen |> Ray.Backend.delete

    brdf_lut
end

function _prefilter(
    fb::Ray.Backend.Framebuffer, environment_map::Ray.Backend.Cubemap,
    cube::Ray.Backend.VertexArray, projection_views::Vector{Mat4f0},
    width::Integer = 128, height::Integer = 128,
)
    cubemap = Ray.Backend.Cubemap(
        width, height,
        internal_format=GL_RGB16F, data_format=GL_RGB, type=GL_UNSIGNED_SHORT,
        min_filter=GL_LINEAR_MIPMAP_LINEAR, generate_mips=true,
    )
    shader = Ray.get_asset_shader("prefilter")

    shader |> Ray.Backend.bind
    environment_map |> Ray.Backend.bind
    Ray.Backend.upload_uniform(shader, "u_EnvironmentMap", 0)

    max_mip_level = 5
    for mip in 0:(max_mip_level - 1)
        mip_width::UInt32 = width * (0.5 ^ mip)
        mip_height::UInt32 = height * (0.5 ^ mip)
        Ray.Backend.set_viewport(mip_width, mip_height)
        # Set depth attachment for the current mip.
        depth_attachment = Ray.Backend.Texture2D(
            mip_width, mip_height, GL_UNSIGNED_INT,
            internal_format=GL_DEPTH_COMPONENT24, data_format=GL_DEPTH_COMPONENT,
        )
        # There is only one depth attachment per framebuffer (0th level).
        Ray.Backend.attach!(
            fb, GL_DEPTH_ATTACHMENT,
            Ray.Backend.Attachment(GL_TEXTURE_2D, 0, depth_attachment),
        )
        Ray.Backend.upload_uniform(
            shader, "u_Roughness", Float32(mip / (max_mip_level - 1))
        )
        _render_to_cubemap(fb, shader, cube, cubemap, projection_views, mip)
        depth_attachment |> Ray.Backend.delete
    end
    shader |> Ray.Backend.delete

    cubemap
end

function _map_to_cubemap(
    fb::Ray.Backend.Framebuffer, irradiance_map::Ray.Backend.Texture2D,
    cube::Ray.Backend.VertexArray, projection_views::Vector{Mat4f0},
    cubemap_width::Integer = 512, cubemap_height::Integer = 512,
)
    cubemap = Ray.Backend.Cubemap(
        cubemap_width, cubemap_height,
        internal_format=GL_RGB16F, data_format=GL_RGB, type=GL_UNSIGNED_SHORT,
        min_filter=GL_LINEAR_MIPMAP_LINEAR,
    )
    depth_attachment = Ray.Backend.Texture2D(
        cubemap_width, cubemap_height, GL_UNSIGNED_INT,
        internal_format=GL_DEPTH_COMPONENT24, data_format=GL_DEPTH_COMPONENT,
    )
    Ray.Backend.attach!(fb, GL_DEPTH_ATTACHMENT, Ray.Backend.Attachment(
        GL_TEXTURE_2D, 0, depth_attachment,
    ))
    shader = Ray.get_asset_shader("from-rectangle-to-cubemap")

    shader |> Ray.Backend.bind
    irradiance_map |> Ray.Backend.bind
    Ray.Backend.set_viewport(cubemap_width, cubemap_height)
    Ray.Backend.upload_uniform(shader, "u_EquirectangularMap", 0)

    _render_to_cubemap(fb, shader, cube, cubemap, projection_views)

    shader |> Ray.Backend.delete
    depth_attachment |> Ray.Backend.delete

    cubemap
end

function _convolve(
    fb::Ray.Backend.Framebuffer, environment_cubemap::Ray.Backend.Cubemap,
    cube::Ray.Backend.VertexArray, projection_views::Vector{Mat4f0},
    conv_width::Integer = 32, conv_height::Integer = 32,
)
    convolution_cubemap = Ray.Backend.Cubemap(
        conv_width, conv_height,
        internal_format=GL_RGB16F, data_format=GL_RGB, type=GL_UNSIGNED_SHORT,
    )
    convolution_depth_attachment = Ray.Backend.Texture2D(
        conv_width, conv_height, GL_UNSIGNED_INT,
        internal_format=GL_DEPTH_COMPONENT24, data_format=GL_DEPTH_COMPONENT,
    )
    shader = Ray.get_asset_shader("cubemap-convolution")

    Ray.Backend.set_viewport(conv_width, conv_height)

    shader |> Ray.Backend.bind
    environment_cubemap |> Ray.Backend.bind
    environment_cubemap |> Ray.Backend.generate_mips
    Ray.Backend.upload_uniform(shader, "u_EnvironmentMap", 0)

    Ray.Backend.attach!(fb, GL_DEPTH_ATTACHMENT, Ray.Backend.Attachment(
        GL_TEXTURE_2D, 0, convolution_depth_attachment,
    ))

    _render_to_cubemap(
        fb, shader, cube, convolution_cubemap, projection_views,
    )

    shader |> Ray.Backend.delete
    convolution_depth_attachment |> Ray.Backend.delete

    convolution_cubemap
end

function _render_to_cubemap(
    fb::Ray.Backend.Framebuffer, shader::Ray.Backend.Shader,
    cube::Ray.Backend.VertexArray, cubemap::Ray.Backend.Cubemap,
    projection_views::Vector{Mat4f0}, mip::Integer = 0,
)
    for (i, projection_view) in enumerate(projection_views)
        color_attachment = Ray.Backend.Attachment(
            GL_TEXTURE_CUBE_MAP_POSITIVE_X + i - 1, mip, cubemap,
        )
        Ray.Backend.attach!(fb, GL_COLOR_ATTACHMENT0, color_attachment)
        Ray.Backend.upload_uniform(shader, "u_ViewProjection", projection_view)

        Ray.Backend.clear()
        cube |> Ray.Backend.draw_indexed
    end
end

function _get_projection_views()
    projection = Ray.Transformations.perspective(90f0, 1f0, 0.1f0, 10f0)
    views = [
        Ray.Transformations.look_at(Point3f0(0, 0, 0), Point3f0( 1,  0,  0), Point3f0(0, -1,  0)),
        Ray.Transformations.look_at(Point3f0(0, 0, 0), Point3f0(-1,  0,  0), Point3f0(0, -1,  0)),
        Ray.Transformations.look_at(Point3f0(0, 0, 0), Point3f0( 0,  1,  0), Point3f0(0,  0,  1)),
        Ray.Transformations.look_at(Point3f0(0, 0, 0), Point3f0( 0, -1,  0), Point3f0(0,  0, -1)),
        Ray.Transformations.look_at(Point3f0(0, 0, 0), Point3f0( 0,  0,  1), Point3f0(0, -1,  0)),
        Ray.Transformations.look_at(Point3f0(0, 0, 0), Point3f0( 0,  0, -1), Point3f0(0, -1,  0)),
    ]
    [projection * view for view in views]
end
