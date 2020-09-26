module Transformations
export translation, rotation_x, rotation_y, rotation_z, orthographic,
    scaling, perspective, look_at, rot_at

using LinearAlgebra: I, normalize
using StaticArrays

function translation(x::T, y::T, z::T)::SMatrix{4, 4, Float32} where T <: Number
    SMatrix{4, 4, Float32}(
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        x, y, z, 1.0,
    )
end
translation(t::AbstractVector{T}) where T <: Number =
    translation(t[1], t[2], t[3])

# All rotations are counterclockwise for positive angles
function rotation_x(angle::T) where T
    SMatrix{4, 4, Float32}(
        1.0, 0.0, 0.0, 0.0,
        0.0, cos(angle), sin(angle), 0.0,
        0.0, -sin(angle), cos(angle),  0.0,
        0.0, 0.0, 0.0, 1.0
    )
end

function rotation_y(angle::T) where T
    SMatrix{4, 4, Float32}(
        cos(angle), 0.0, -sin(angle),  0.0,
        0.0, 1.0, 0.0, 0.0,
        sin(angle), 0.0, cos(angle), 0.0,
        0.0, 0.0, 0.0, 1.0
    )
end

function rotation_z(angle::T)::SMatrix{4, 4, Float32} where T <: Number
    SMatrix{4, 4, Float32}(
        cos(angle), sin(angle), 0.0, 0.0,
        -sin(angle), cos(angle),  0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
    )
end

function scaling(sx::T, sy::T, sz::T) where T <: Number
    SMatrix{4, 4, Float32}(
        sx, 0, 0, 0,
        0, sy, 0, 0,
        0, 0, sz, 0,
        0, 0, 0, 1,
    )
end

function _frustum(
    left::T, right::T,
    bottom::T, top::T,
    znear::T, zfar::T,
)::SMatrix{4, 4, Float32} where T <: Number
    (right == left || bottom == top || znear == zfar) &&
        return SMatrix{4, 4, Float32}(I)

    SMatrix{4, 4, Float32}(
        2.0 * znear / (right - left), 0.0, 0.0, 0.0,
        0.0, 2.0 * znear / (top - bottom), 0.0, 0.0,
        (right + left) / (right - left), (top + bottom) / (top - bottom), -(zfar + znear) / (zfar - znear), -1.0,
        0.0, 0.0, (-2.0 * znear * zfar) / (zfar - znear), 0.0
    )
end

function perspective(
    fovy::T, aspect::T, znear::T, zfar::T,
)::SMatrix{4, 4, Float32} where T <: Number
    (znear == zfar) &&
        error("znear ($znear) must be different from zfar ($zfar)")

    h = tan(fovy / 360.0 * π) * znear
    w = h * aspect
    _frustum(-w, w, -h, h, znear, zfar)
end

function orthographic(
    left::T, right::T, bottom::T, top::T, znear::T, zfar::T,
)::SMatrix{4, 4, Float32} where T <: Number
    (znear == zfar) &&
        error("znear ($znear) must be different from zfar ($zfar)")

    SMatrix{4, 4, Float32}(
        2f0 / (right - left), 0f0, 0f0,  0f0,
        0f0, 2f0 / (top - bottom), 0f0,  0f0,
        0f0, 0f0, -2f0 / (zfar - znear), 0f0,
        -(right + left) / (right - left), -(top + bottom) / (top - bottom), -(zfar + znear) / (zfar - znear), 1f0,
    )
end

function look_at(
    position::AbstractVector{T}, target::AbstractVector{T}, up::AbstractVector{T},
)::SMatrix{4, 4, Float32} where T <: Number
    z_axis = (position - target) |> normalize
    x_axis = (up × z_axis) |> normalize
    y_axis = (z_axis × x_axis) |> normalize

    SMatrix{4, 4, Float32}(
        x_axis[1], y_axis[1], z_axis[1], 0f0,
        x_axis[2], y_axis[2], z_axis[2], 0f0,
        x_axis[3], y_axis[3], z_axis[3], 0f0,
        0f0, 0f0, 0f0, 1f0,
    ) * translation(-position)
end

function rot_at(
    position::AbstractVector{T}, target::AbstractVector{T}, up::AbstractVector{T},
)::SMatrix{4, 4, Float32} where T <: Number
    z_axis = normalize(position - target)
    x_axis = normalize(up × z_axis)
    y_axis = normalize(z_axis × x_axis)

    SMatrix{4, 4, Float32}(
        x_axis[1], y_axis[1], z_axis[1], 0f0,
        x_axis[2], y_axis[2], z_axis[2], 0f0,
        x_axis[3], y_axis[3], z_axis[3], 0f0,
        0f0, 0f0, 0f0, 1f0,
    )
end

end
