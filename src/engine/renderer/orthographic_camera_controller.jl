mutable struct OrthographicCameraController
    camera::OrthographicCamera

    zoom_level::Float32
    aspect_ratio::Float32
    rotation::Bool

    camera_position::Vec3f0
    camera_rotation::Float32
    camera_translation_speed::Float32
    camera_rotation_speed::Float32
end

function OrthographicCameraController(aspect_ratio::Float32, rotation::Bool)
    zoom_level = 1f0
    camera = OrthographicCamera(
        -aspect_ratio * zoom_level, aspect_ratio * zoom_level,
        -zoom_level, zoom_level,
    )

    OrthographicCameraController(
        camera, zoom_level, aspect_ratio, rotation,
        Vec3f0(0f0, 0f0, 0f0),
        0f0,
        5f0, 180f0,
    )
end

function on_update(controller::OrthographicCameraController, timestep::Float32)
    rad = deg2rad(controller.camera_rotation) |> Float32
    t_speed = controller.camera_translation_speed
    r_speed = controller.camera_rotation_speed

    if is_key_pressed(GLFW.KEY_A)
        x_pos = cos(rad) * t_speed * timestep
        y_pos = sin(rad) * t_speed * timestep
        controller.camera_position -= Vec3f0(x_pos, y_pos, 0f0)
    elseif is_key_pressed(GLFW.KEY_D)
        x_pos = cos(rad) * t_speed * timestep
        y_pos = sin(rad) * t_speed * timestep
        controller.camera_position += Vec3f0(x_pos, y_pos, 0f0)
    end

    if is_key_pressed(GLFW.KEY_W)
        x_pos = -sin(rad) * t_speed * timestep
        y_pos = cos(rad) * t_speed * timestep
        controller.camera_position += Vec3f0(x_pos, y_pos, 0f0)
    elseif is_key_pressed(GLFW.KEY_S)
        x_pos = -sin(rad) * t_speed * timestep
        y_pos = cos(rad) * t_speed * timestep
        controller.camera_position -= Vec3f0(x_pos, y_pos, 0f0)
    end

    if controller.rotation
        if is_key_pressed(GLFW.KEY_Q)
            controller.camera_rotation += r_speed * timestep
        elseif is_key_pressed(GLFW.KEY_E)
            controller.camera_rotation -= r_speed * timestep
        end

        if controller.camera_rotation > 180f0
            controller.camera_rotation -= 360f0
        elseif controller.camera_rotation < -180f0
            controller.camera_rotation += 360f0
        end

        set_rotation!(controller.camera, controller.camera_rotation)
    end

    set_position!(controller.camera, controller.camera_position)
    controller.camera_translation_speed = controller.zoom_level
end

function on_event(
    controller::OrthographicCameraController, event::Event.MouseScrolled,
)
    controller.zoom_level -= event.y_offset * 0.25f0
    controller.zoom_level = max(controller.zoom_level, 0.25f0)

    set_projection!(
        controller.camera,
        -controller.aspect_ratio * controller.zoom_level,
        controller.aspect_ratio * controller.zoom_level,
        -controller.zoom_level, controller.zoom_level,
    )
end

on_event(controller::OrthographicCameraController, event::Event.WindowResize) =
    on_resize(controller, Float32(event.width), Float32(event.height))

function on_resize(
    controller::OrthographicCameraController, width::Float32, height::Float32,
)
    controller.aspect_ratio = width / height
    set_projection!(
        controller.camera,
        -controller.aspect_ratio * controller.zoom_level,
        controller.aspect_ratio * controller.zoom_level,
        -controller.zoom_level, controller.zoom_level,
    )
end
