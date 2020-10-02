module PerspectiveCameraModule
export PerspectiveCamera

using LinearAlgebra: normalize, ×
using GeometryBasics

using Ray.Transformations

mutable struct PerspectiveCamera
    projection::Mat4f0
    view::Mat4f0
    view_projection::Mat4f0

    position::Point3f0

    front::Vec3f0
    right::Vec3f0
    up::Vec3f0

    world_up::Vec3f0

    yaw::Float32
    pitch::Float32

    function PerspectiveCamera(;
        aspect::Float32,
        fov::Float32 = 45f0,
        near::Float32 = 0.1f0, far::Float32 = 1000f0,
        position::Point3f0 = Point3f0(0f0, 0f0, -3f0),
    )
        projection = perspective(fov, aspect, near, far)

        camera = new(
            projection, zeros(Mat4f0), zeros(Mat4f0),
            position,
            zeros(Vec3f0), zeros(Vec3f0), zeros(Vec3f0),
            Vec3f0(0f0, 1f0, 0f0),
            -90f0, 0f0,
        ) |> _update_camera!

        camera.view = look_at(
            camera.position, camera.position + camera.front, camera.up,
        )
        camera.view_projection = camera.projection * camera.view

        camera
    end
end

function _update_camera!(camera::PerspectiveCamera)::PerspectiveCamera
    pitch_rad = camera.pitch |> deg2rad
    pitch_cos = pitch_rad |> cos
    yaw_rad = camera.yaw |> deg2rad

    camera.front = Vec3f0(
        cos(yaw_rad) * pitch_cos, sin(pitch_rad), sin(yaw_rad) * pitch_cos,
    ) |> normalize
    camera.right = (camera.front × camera.world_up) |> normalize
    camera.up = (camera.right × camera.front) |> normalize

    camera
end

end
