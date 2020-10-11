struct Cubemap
    id::UInt32
    width::UInt32
    height::UInt32

    internal_format::UInt32
    data_format::UInt32
    type::UInt32
end

function Cubemap(
    width::Integer, height::Integer;
    internal_format::UInt32 = GL_RGB16F, data_format::UInt32 = GL_RGB,
    type::UInt32 = GL_FLOAT, kwargs...,
)
    id = @ref glGenTextures(1, RepUInt32)
    glBindTexture(GL_TEXTURE_CUBE_MAP, id)

    for i in 1:6
        glTexImage2D(
            GL_TEXTURE_CUBE_MAP_POSITIVE_X + i - 1, 0, internal_format,
            width, height, 0, GL_RGB, type, C_NULL,
        )
    end

    _set_cubemap_parameters(;kwargs...)
    Cubemap(id, width, height, internal_format, data_format, type)
end

function _set_cubemap_parameters(;
    wrap_s::UInt32 = GL_CLAMP_TO_EDGE,
    wrap_t::UInt32 = GL_CLAMP_TO_EDGE,
    wrap_r::UInt32 = GL_CLAMP_TO_EDGE,
    min_filter::UInt32 = GL_LINEAR, mag_filter::UInt32 = GL_LINEAR,
)
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, wrap_s)
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, wrap_t)
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, wrap_r)
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, min_filter)
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, mag_filter)
end

bind(cb::Cubemap) = glBindTexture(GL_TEXTURE_CUBE_MAP, cb.id)
unbind(::Cubemap) = glBindTexture(GL_TEXTURE_CUBE_MAP, 0)
