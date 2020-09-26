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
