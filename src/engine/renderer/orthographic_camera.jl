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

mutable struct OrthographicCamera
    projection::Mat4f0
    view::Mat4f0
    view_projection::Mat4f0

    position::Vec3f0
    rotation::Float32 # z axis rotation

    function OrthographicCamera(
        left::Float32, right::Float32, bottom::Float32, top::Float32,
    )
        projection = orthographic(left, right, bottom, top, -1f0, 1f0)
        camera = new(
            projection, zeros(Mat4f0), zeros(Mat4f0), zeros(Vec3f0), 0f0,
        )
        _recalculate_view!(camera)
        camera
    end
end

function set_projection!(
    camera::OrthographicCamera, left::Float32, right::Float32,
    bottom::Float32, top::Float32,
)
    camera.projection = orthographic(left, right, bottom, top, -1f0, 1f0)
    camera.view_projection = camera.projection * camera.view
end

function set_rotation!(camera::OrthographicCamera, rotation::Float32)
    camera.rotation = rotation
    _recalculate_view!(camera)
end

function set_position!(camera::OrthographicCamera, position::Vec3f0)
    camera.position = position
    _recalculate_view!(camera)
end

function _recalculate_view!(camera::OrthographicCamera)
    camera.view = inv(translation(camera.position)
        * rotation_z(deg2rad(camera.rotation)))
    camera.view_projection = camera.projection * camera.view
end
