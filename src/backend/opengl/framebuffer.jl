mutable struct Framebuffer <: Abstractions.Framebuffer
    id::UInt32
    color_attachment::UInt32
    depth_attachment::UInt32
    spec::Abstractions.FramebufferSpec

    function Framebuffer(spec::Abstractions.FramebufferSpec)
        id, color_attachment, depth_attachment = _recreate(spec)
        new(id, color_attachment, depth_attachment, spec)
    end
end

function _recreate(spec::Abstractions.FramebufferSpec)
    id = @ref glGenRenderbuffers(1, RepUInt32)
    glBindRenderbuffer(id)

    color_attachment = Texture2D(spec.width, spec.height)
    depth_attachment = Texture2D(
        spec.width, spec.height, internal_format=GL_DEPTH24_STENCIL8,
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
    id, color_attachment, depth_attachment = _recreate(spec)

    fb.id = id
    fb.color_attachment = color_attachment
    fb.depth_attachment = depth_attachment
end
