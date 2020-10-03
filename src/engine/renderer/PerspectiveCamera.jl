module PerspectiveCameraModule
export PerspectiveCamera, PerspectiveCameraController,
    set_rotation!, set_position!, on_resize!

using LinearAlgebra: normalize, ×
using GeometryBasics
using GLFW

using Ray.Input
using Ray.Event
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
        aspect_ratio::Float32,
        fov::Float32 = 45f0, near::Float32 = 0.1f0, far::Float32 = 1000f0,
        position::Point3f0 = Point3f0(0f0, 0f0, -3f0),
    )
        projection = perspective(fov, aspect_ratio, near, far)

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

function set_position!(camera::PerspectiveCamera, position::Point3f0)
    camera.position = position
    camera |> _update_camera!
end

function set_rotation!(camera::PerspectiveCamera, pitch::Float32, yaw::Float32)
    camera.pitch = pitch
    camera.yaw = yaw
    camera |> _update_camera!
end

function set_projection!(
    camera::PerspectiveCamera,
    aspect_ratio::Float32, fov::Float32, near::Float32, far::Float32,
)
    camera.projection = perspective(fov, aspect_ratio, near, far)
    camera |> _update_camera!
end

mutable struct PerspectiveCameraController
    camera::PerspectiveCamera

    speed::Float32
    sensitivity::Float32

    zoom_level::Float32
    aspect_ratio::Float32

    fov::Float32
    near::Float32
    far::Float32

    camera_position::Point3f0
    yaw::Float32
    pitch::Float32

    mouse_last::Point2f0
    mouse_pos::Point2f0
end

function PerspectiveCameraController(;
    aspect_ratio::Float32,
    fov::Float32 = 45f0, near::Float32 = 0.1f0, far::Float32 = 1000f0,
    speed::Float32 = 1f0,
    sensitivity::Float32=0.05f0, kwargs...,
)
    camera = PerspectiveCamera(;
        aspect_ratio=aspect_ratio, fov=fov, near=near, far=far,
        kwargs...,
    )
    PerspectiveCameraController(
        camera,
        speed, sensitivity,
        1f0, aspect_ratio,
        fov, near, far,
        camera.position, camera.yaw, camera.pitch,
        zeros(Point2f0), zeros(Point2f0),
    )
end

function on_update(controller::PerspectiveCameraController, timestep::Float32)
    speed = controller.speed * timestep

    if is_key_pressed(GLFW.KEY_W)
        controller.camera_position += speed * controller.camera.front
    elseif is_key_pressed(GLFW.KEY_S)
        controller.camera_position -= speed * controller.camera.front
    end

    if is_key_pressed(GLFW.KEY_A)
        controller.camera_position -= speed * normalize(
            controller.camera.front × controller.camera.up,
        )
    elseif is_key_pressed(GLFW.KEY_D)
        controller.camera_position += speed * normalize(
            controller.camera.front × controller.camera.up,
        )
    end

    controller.mouse_pos = Point2f0(get_mouse_position()...)
    offset = controller.mouse_pos - controller.mouse_last
    offset *= controller.sensitivity

    controller.yaw += offset[1]
    controller.pitch += offset[2]
    controller.pitch = clamp.(controller.pitch, -89f0, 89f0)

    controller.mouse_last = controller.mouse_pos

    set_position!(controller.camera, controller.camera_position)
    set_rotation!(controller.camera, controller.pitch, controller.yaw)
end

function on_event(
    controller::PerspectiveCameraController, event::Event.MouseScrolled,
)
    controller.zoom_level -= event.y_offset * 0.25f0
    controller.zoom_level = max(0.25f0, controller.zoom_level)

    set_projection!(
        controller.camera,
        controller.aspect_ratio, controller.zoom_level * controller.fov,
        controller.near, controller.far,
    )
end

on_event(controller::PerspectiveCameraController, event::Event.WindowResize) =
    on_resize!(controller, Float32(event.width), Float32(event.height))

function on_resize!(
    controller::PerspectiveCameraController, width::Float32, height::Float32,
)
    controller.aspect_ratio = width / height
    set_projection!(
        controller.camera,
        controller.aspect_ratio, controller.zoom_level * controller.fov,
        controller.near, controller.far,
    )
end

end
