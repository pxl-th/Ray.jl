struct Texture2D
    id::UInt32
    width::UInt32
    height::UInt32
    path::String

    internal_format::UInt32
    data_format::UInt32
    type::UInt32
end

function Texture2D(width::Integer, height::Integer, type::UInt32 = GL_UNSIGNED_BYTE)
    internal_format = GL_RGBA8
    data_format = GL_RGBA

    id = @ref glGenTextures(1, RepUInt32)
    glBindTexture(GL_TEXTURE_2D, id)
    glTexImage2D(
        GL_TEXTURE_2D, 0, internal_format,
        width, height, 0, data_format, type, C_NULL,
    )

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

    Texture2D(id, width, height, "", internal_format, data_format, type)
end

function Texture2D(path::String, type::UInt32 = GL_UNSIGNED_BYTE)
    data, width, height, pixel_type = load_image(path, true)

    if length(pixel_type) == 3
        internal_format = GL_RGB8
        data_format = GL_RGB
    elseif length(pixel_type) == 4
        internal_format = GL_RGBA
        data_format = GL_RGBA
    end

    id = @ref glGenTextures(1, RepUInt32)
    glBindTexture(GL_TEXTURE_2D, id)
    glTexImage2D(
        GL_TEXTURE_2D, 0, internal_format,
        width, height, 0, data_format, type, data,
    )

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

    Texture2D(id, width, height, path, internal_format, data_format, type)
end

function bind(texture::Texture2D, slot::Integer = 0)
    glActiveTexture(GL_TEXTURE0 + slot)
    glBindTexture(GL_TEXTURE_2D, texture.id)
end

function set_data!(texture::Texture2D, data::AbstractArray, size::Integer)
    bpp = texture.data_format == GL_RGBA ? 4 : 3
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
