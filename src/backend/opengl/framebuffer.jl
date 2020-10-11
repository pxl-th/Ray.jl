mutable struct Framebuffer <: Abstractions.Framebuffer
    id::UInt32
    color_attachment::Union{Texture2D, Nothing}
    depth_attachment::Union{Texture2D, Nothing}
    spec::Abstractions.FramebufferSpec

end

function Framebuffer(spec::Abstractions.FramebufferSpec)
    id, color_attachment, depth_attachment = _recreate(spec)
    Framebuffer(id, color_attachment, depth_attachment, spec)
end

"""
TODO:
- support for arbitrary amount of attachments
- create empty as well as supplied with attachments (store in dict)
- resizable or not (by default --- not)
- ditch specs
"""

function _recreate(spec::Abstractions.FramebufferSpec)
    id = @ref glGenFramebuffers(1, RepUInt32)
    glBindFramebuffer(GL_FRAMEBUFFER, id)

    color_attachment = Texture2D(
        spec.width, spec.height,
        internal_format=GL_RGB8, data_format=GL_RGB,
    )
    depth_attachment = Texture2D(
        spec.width, spec.height, GL_UNSIGNED_INT_24_8,
        internal_format=GL_DEPTH24_STENCIL8, data_format=GL_DEPTH_STENCIL,
    )

    glFramebufferTexture2D(
        GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
        GL_TEXTURE_2D, color_attachment.id, 0,
    )
    glFramebufferTexture2D(
        GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT,
        GL_TEXTURE_2D, depth_attachment.id, 0,
    )

    !is_complete() && error("Framebuffer is incomplete.")
    glBindFramebuffer(GL_FRAMEBUFFER, 0)
    id, color_attachment, depth_attachment
end

is_complete()::Bool =
    glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE

bind(fb::Framebuffer) = glBindFramebuffer(GL_FRAMEBUFFER, fb.id)
unbind(::Framebuffer) = glBindFramebuffer(GL_FRAMEBUFFER, 0)

function delete(fb::Framebuffer)
    glDeleteFramebuffers(1, Ref(fb.id))
    delete(fb.color_attachment)
    delete(fb.depth_attachment)
end

function resize!(fb::Framebuffer, width::UInt32, height::UInt32)
    delete(fb)

    fb.spec = Abstractions.FramebufferSpec(width, height, fb.spec.samples)
    id, color_attachment, depth_attachment = _recreate(fb.spec)

    fb.id = id
    fb.color_attachment = color_attachment
    fb.depth_attachment = depth_attachment
end
