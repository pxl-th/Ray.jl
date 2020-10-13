struct Texture2D
    id::UInt32
    width::UInt32
    height::UInt32
    path::String

    internal_format::UInt32
    data_format::UInt32
    type::UInt32
end

function Texture2D(
    width::Integer, height::Integer, type::UInt32 = GL_UNSIGNED_BYTE;
    internal_format::UInt32 = GL_RGBA8, data_format::UInt32 = GL_RGBA,
    kwargs...,
)
    id = @ref glGenTextures(1, RepUInt32)
    glBindTexture(GL_TEXTURE_2D, id)
    glTexImage2D(
        GL_TEXTURE_2D, 0, internal_format,
        width, height, 0, data_format, type, C_NULL,
    )

    _set_texture_parameters(kwargs...)
    Texture2D(id, width, height, "", internal_format, data_format, type)
end

function Texture2D(
    path::String, type::UInt32 = GL_UNSIGNED_BYTE;
    internal_format::Union{Nothing, UInt32} = nothing,
    data_format::Union{Nothing, UInt32} = nothing,
    kwargs...,
)
    data, width, height, pixel_type = load_image(path, true)
    @info path
    @info pixel_type

    if internal_format ≡ nothing
        if length(pixel_type) == 3
            internal_format = GL_RGB8
        elseif length(pixel_type) == 1
            internal_format = GL_RED
        elseif length(pixel_type) == 4
            internal_format = GL_RGBA8
        end
    end
    if data_format ≡ nothing
        if length(pixel_type) == 3
            data_format = GL_RGB
        elseif length(pixel_type) == 1
            data_format = GL_RED
        elseif length(pixel_type) == 4
            data_format = GL_RGBA
        end
    end

    id = @ref glGenTextures(1, RepUInt32)
    glBindTexture(GL_TEXTURE_2D, id)
    glTexImage2D(
        GL_TEXTURE_2D, 0, internal_format,
        width, height, 0, data_format, type, data,
    )

    _set_texture_parameters(kwargs...)
    Texture2D(id, width, height, path, internal_format, data_format, type)
end

function _set_texture_parameters(;
    min_filter::UInt32 = GL_LINEAR, mag_filter::UInt32 = GL_LINEAR,
    wrap_s::UInt32 = GL_REPEAT, wrap_t::UInt32 = GL_REPEAT,
)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, min_filter)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, mag_filter)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrap_s)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrap_t)
end

function bind(texture::Texture2D, slot::Integer = 0)
    glActiveTexture(GL_TEXTURE0 + slot)
    glBindTexture(GL_TEXTURE_2D, texture.id)
end

function set_data!(texture::Texture2D, data::AbstractArray, size::Integer)
    if texture.data_format == GL_RGBA
        bpp = 4
    elseif texture.data_format == GL_RGB
        bpp = 3
    elseif texture.data_format == GL_RED
        bpp = 1
    else
        error("Unknown data format $(texture.data_format)")
    end

    (size != bpp * texture.width * texture.height) &&
        error("Data must be entire texture.")

    glBindTexture(GL_TEXTURE_2D, texture.id)
    glTexSubImage2D(
        GL_TEXTURE_2D, 0,
        0, 0, texture.width, texture.height,
        texture.data_format, texture.type, data,
    )
end

delete(texture::Texture2D) = glDeleteTextures(1, Ref(texture.id))

function load_image(path::String, vertical_flip::Bool = false)
    !isfile(path) && error("File [$path] does not exist.")

    data = Images.load(path)
    data = permutedims(data, (2, 1))
    vertical_flip && (data = data[:, end:-1:1])

    width, height = size(data)
    pixel_type = eltype(data)

    data, width, height, pixel_type
end
