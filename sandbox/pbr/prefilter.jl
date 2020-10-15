function prefilter(
    environment_map::Ray.Backend.Cubemap,
    width::Integer = 128, height::Integer = 128,
)
    @info "Environment cubemap resolution $(environment_map.width)x$(environment_map.height)"
    prefiltered_cubemap = Ray.Backend.Cubemap(
        width, height,
        internal_format=GL_RGB16F, data_format=GL_RGB, type=GL_UNSIGNED_SHORT,
        min_filter=GL_LINEAR_MIPMAP_LINEAR, generate_mips=true,
    )
    shader = Ray.Backend.Shader(
        raw"C:\Users\tonys\projects\julia\Ray\assets\shaders\prefilter.glsl",
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

    fb = Ray.Backend.Framebuffer()
    fb |> Ray.Backend.bind
    shader |> Ray.Backend.bind

    Ray.Backend.set_clear_color(0, 0, 0, 1)
    Ray.Backend.enable_depth()

    cubebox |> Ray.Backend.bind
    environment_map |> Ray.Backend.bind
    Ray.Backend.upload_uniform(shader, "u_EnvironmentMap", 0)

    max_mip_level = 5
    for mip in 0:(max_mip_level - 1)
        mip_width::UInt32 = width * (0.5 ^ mip)
        mip_height::UInt32 = height * (0.5 ^ mip)
        Ray.Backend.set_viewport(mip_width, mip_height)
        # Set depth attachment for current mip.
        depth_attachment = Ray.Backend.Texture2D(
            mip_width, mip_height, GL_UNSIGNED_INT,
            internal_format=GL_DEPTH_COMPONENT24, data_format=GL_DEPTH_COMPONENT,
        )
        # There is only one depth attachment per framebuffer (0th level).
        Ray.Backend.attach!(
            fb, GL_DEPTH_ATTACHMENT,
            Ray.Backend.Attachment(GL_TEXTURE_2D, 0, depth_attachment),
        )
        roughness::Float32 = mip / (max_mip_level - 1)
        Ray.Backend.upload_uniform(shader, "u_Roughness", roughness)
        # Render to 6 faces of the cube.
        for (i, view) in enumerate(views)
            Ray.Backend.attach!(
                fb, GL_COLOR_ATTACHMENT0, Ray.Backend.Attachment(
                    GL_TEXTURE_CUBE_MAP_POSITIVE_X + i - 1, mip,
                    prefiltered_cubemap,
                ),
            )
            Ray.Backend.upload_uniform(
                shader, "u_ViewProjection", projection * view,
            )
            Ray.Backend.clear()
            cubebox |> Ray.Backend.draw_indexed
        end
        depth_attachment |> Ray.Backend.delete
    end

    fb |> Ray.Backend.unbind
    # TODO delete framebuffer
    cubebox |> Ray.Backend.delete
    shader |> Ray.Backend.delete

    prefiltered_cubemap
end
