struct Attachment
    target::UInt32
    level::UInt32
    attachment::Union{Texture2D, Cubemap}
end

mutable struct Framebuffer <: Abstractions.Framebuffer
    id::UInt32
    attachments::Dict{UInt32, Attachment}
    resizable::Bool
end

function Framebuffer(
    attachments::Dict{UInt32, Attachment} = Dict{UInt32, Attachment}(),
)
    id = @ref glGenFramebuffers(1, RepUInt32)
    glBindFramebuffer(GL_FRAMEBUFFER, id)

    for (type, attachment) in attachments
        glFramebufferTexture2D(
            GL_FRAMEBUFFER, type, attachment.target,
            attachment.attachment.id, attachment.level,
        )
    end

    glBindFramebuffer(GL_FRAMEBUFFER, 0)
    Framebuffer(id, attachments, false)
end

function Framebuffer(width::Integer, height::Integer)
    id = @ref glGenFramebuffers(1, RepUInt32)
    glBindFramebuffer(GL_FRAMEBUFFER, id)

    attachments = _get_default_attachments(width, height)
    for (type, attachment) in attachments
        glFramebufferTexture2D(
            GL_FRAMEBUFFER, type, attachment.target,
            attachment.attachment.id, attachment.level,
        )
    end

    glBindFramebuffer(GL_FRAMEBUFFER, 0)
    Framebuffer(id, attachments, true)
end

is_complete(fb::Framebuffer)::Bool =
    glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE

function attach!(fb::Framebuffer, type::UInt32, attachment::Attachment)
    glFramebufferTexture2D(
        GL_FRAMEBUFFER, type, attachment.target,
        attachment.attachment.id, attachment.level,
    )
    fb.attachments[type] = attachment
end

bind(fb::Framebuffer) = glBindFramebuffer(GL_FRAMEBUFFER, fb.id)
unbind(::Framebuffer) = glBindFramebuffer(GL_FRAMEBUFFER, 0)

function _get_default_attachments(width::Integer, height::Integer)
    color_attachment = Texture2D(
        width, height, internal_format=GL_RGB8, data_format=GL_RGB,
    )
    depth_attachment = Texture2D(
        width, height, GL_UNSIGNED_INT_24_8,
        internal_format=GL_DEPTH24_STENCIL8, data_format=GL_DEPTH_STENCIL,
    )
    Dict{UInt32, Attachment}(
        GL_COLOR_ATTACHMENT0 => Attachment(
            GL_TEXTURE_2D, UInt32(0), color_attachment,
        ),
        GL_DEPTH_STENCIL_ATTACHMENT => Attachment(
            GL_TEXTURE_2D, UInt32(0), depth_attachment,
        ),
    )
end

"""
TODO:
- resizing
- deletion
- detaching
"""

function resize!(fb::Framebuffer, width::UInt32, height::UInt32)
    if !fb.resizable
        @warn "Framebuffer is not resizable."
        return
    end
    (width == 0 || height == 0) && return
    @info "Resizing to $width x $height NOT YET READY"
end

# function detach!(fb::Framebuffer, attachment_type::UInt32)
#     attachment_type in keys(fb.attachments) &&
#         pop!(fb.attachments, attachment_type)
# end

# function delete(fb::Framebuffer)
#     glDeleteFramebuffers(1, Ref(fb.id))
#     for key in keys(fb.attachments)
#         target, attachment = pop!(fb.attachments, key)
#         delete(attachment)
#     end
# end
