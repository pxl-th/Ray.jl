module OrthographicCameraModule
export OrthographicCamera, OrthographicCameraController,
    set_position!, set_rotation!, set_projection!

using StaticArrays
using GeometryBasics
using GLFW

using Ray.Transformations
using Ray.Event
using Ray.Input

include("orthographic_camera.jl")
include("orthographic_camera_controller.jl")

end
