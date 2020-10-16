module HyperElastic

using LinearAlgebra: I, norm, det
using GeometryBasics

using CImGui
using GLFW
using Ray

struct Particle
    position::Point2f0
    velocity::Vec2f0
    affine_momentum::Mat2f0
    deformation_gradient::Mat2f0
    mass::Float32
    initial_volume::Float32
end

struct Cell
    velocity::Vec2f0
    mass::Float32
end

mutable struct MPM
    grid_resolution::Int32
    num_cells::Int32
    num_particles::Int32

    δt::Float32
    gravity::Float32

    particles::Vector{Particle}
    grid::Matrix{Cell}

    weights::Vector{Point2f0}

    elastic_λ::Float32
    elastic_μ::Float32

    function MPM(;
        grid_resolution::Int32 = 64 |> Int32, δt::Float32 = 0.1f0,
        gravity::Float32 = -0.3f0,
        elastic_λ::Float32 = 20f0, elastic_μ::Float32 = 100f0,
    )
        num_cells = grid_resolution * grid_resolution
        # Initialize points in a square around center of the grid.
        grid, particles = reset_particles(grid_resolution, 0.5f0, 16f0)
        mpm = new(
            grid_resolution, num_cells, length(particles),
            δt, gravity,
            particles, grid,
            Vector{Point2f0}(undef, 3),
            elastic_λ, elastic_μ,
        )

        # Scatter particle mass to the grid.
        particles_to_grid!(mpm)
        # Estimate initial per-particle volume.
        estimate_volume!(mpm)

        mpm
    end
end

function estimate_volume!(mpm::MPM)
    @inbounds for i in 1:mpm.num_particles
        particle = mpm.particles[i]
        # Quadratic interpolation weights.
        cell_idx = floor.(particle.position)
        cell_δ = particle.position .- cell_idx .- 0.5f0
        quadratic_interpolation_weights!(mpm, cell_δ)
        # Accumulate density around immediate neighbourhood.
        density::Float32 = 0f0
        for gx in 0:2, gy in 0:2
            cell_position = Point2f0(cell_idx[1] + gx - 1, cell_idx[2] + gy - 1)
            cell_position = (cell_position .+ 1) .|> Int32
            weight = mpm.weights[gx + 1][1] * mpm.weights[gy + 1][2]
            density += mpm.grid[cell_position...].mass * weight
        end
        # Initial per-particle volume estimate.
        initial_volume = particle.mass / density
        mpm.particles[i] = Particle(
            particle.position, particle.velocity,
            particle.affine_momentum, particle.deformation_gradient,
            particle.mass, initial_volume,
        )
    end
end

function reset_particles(
    grid_resolution::Int32, spacing::Float32, box_size::Float32,
)
    grid_center = grid_resolution / 2f0

    box_iterator = (grid_center - box_size / 2f0):spacing:(grid_center + box_size / 2f0)
    particles = Particle[
        Particle(
            Point2f0(i, j + 3f0), Vec2f0(0f0, 0f0), zeros(Mat2f0),
            Mat2f0(I), 1f0, 0f0,
        ) for i in box_iterator for j in box_iterator
    ]
    grid = Cell[
        Cell(Vec2f0(0f0, 0f0), 0f0)
        for i in 1:grid_resolution, j in 1:grid_resolution
    ]

    grid, particles
end

@inline function quadratic_interpolation_weights!(mpm::MPM, cell_δ::Point2f0)
    mpm.weights[1] = 0.5f0 .* (0.5f0 .- cell_δ) .^ 2
    mpm.weights[2] = 0.75f0 .- cell_δ .^ 2
    mpm.weights[3] = 0.5f0 .* (0.5f0 .+ cell_δ) .^ 2
end

@inline function piola_stress(mpm::MPM, F::Mat2f0, J::Float32)::Mat2f0
    F_inv = inv(F')
    mpm.elastic_μ * (F - F_inv) + mpm.elastic_λ * log(J) * F_inv
end

function particles_to_grid!(mpm::MPM)
    @inbounds for i in 1:mpm.num_particles
        particle = mpm.particles[i]
        # Neo-Hookean hyper-elasticity model.
        F = particle.deformation_gradient
        J = det(F)
        cauchy_stress = (1f0 / J) .* piola_stress(mpm, F, J) * F'
        # Part of the force/momentum fused update for MLS-MPM.
        volume = particle.initial_volume * J
        fuse = -volume * cauchy_stress * mpm.δt * 4f0
        # Quadratic interpolation weights.
        cell_idx = floor.(particle.position)
        cell_δ = particle.position .- cell_idx .- 0.5f0
        quadratic_interpolation_weights!(mpm, cell_δ)
        # Calculate weights for 3x3 immediate neighbouring cells
        # on the grid using interpolation function.
        for gx in 0:2, gy in 0:2
            weight = mpm.weights[gx + 1][1] * mpm.weights[gy + 1][2]
            cell_position = Point2f0(cell_idx[1] + gx - 1, cell_idx[2] + gy - 1)
            cell_distance = (cell_position .- particle.position) .+ 0.5f0
            # Transform to 1-based indexing.
            cell_position = (cell_position .+ 1) .|> Int32
            cell = mpm.grid[cell_position...]
            # Scatter mass to the grid.
            Q = particle.affine_momentum * cell_distance
            mass_contribution = weight * particle.mass
            cell_mass = cell.mass + mass_contribution
            cell_velocity = cell.velocity + mass_contribution * (particle.velocity + Q)
            # Fused force/momentum update.
            cell_velocity += (fuse * weight) * cell_distance
            # At this point, velocity refers to momentum.
            # This gets corrected at grid velocity update step.
            mpm.grid[cell_position...] = Cell(cell_velocity, cell_mass)
        end
    end
end

function grid_velocity_update!(mpm::MPM)
    @inbounds for i in 1:mpm.grid_resolution, j in 1:mpm.grid_resolution
        cell = mpm.grid[i, j]
        cell.mass ≈ 0 && continue
        # Convert momentum to velocity, apply gravity.
        cell_velocity = cell.velocity ./ cell.mass
        cell_velocity += Vec2f0(0f0, mpm.δt * mpm.gravity)
        # Boundary conditions.
        !(2 < i < mpm.grid_resolution - 2) && (cell_velocity *= Vec2f0(0f0, 1f0))
        !(2 < j < mpm.grid_resolution - 2) && (cell_velocity *= Vec2f0(1f0, 0f0))

        mpm.grid[i, j] = Cell(cell_velocity, cell.mass)
    end
end

function grid_to_particles!(mpm::MPM)
    @inbounds for i in 1:mpm.num_particles
        particle = mpm.particles[i]
        particle_velocity = Vec2f0(0f0, 0f0)
        # Quadratic interpolation weights.
        cell_idx = floor.(particle.position)
        cell_δ = particle.position .- cell_idx .- 0.5f0
        quadratic_interpolation_weights!(mpm, cell_δ)
        # Contruct affine per-particle momentum from APIC / MLS-MPM.
        affine_momentum = zeros(Mat2f0)
        for gx in 0:2, gy in 0:2
            weight = mpm.weights[gx + 1][1] * mpm.weights[gy + 1][2]
            cell_position = Point2f0(cell_idx[1] + gx - 1, cell_idx[2] + gy - 1)
            cell_distance = (cell_position .- particle.position) .+ 0.5f0
            # Transform to 1-based indexing.
            cell_position = (cell_position .+ 1) .|> Int32
            weighted_velocity = mpm.grid[cell_position...].velocity * weight
            # Construct inner term for affine momentum.
            inner_term = Mat2f0(
                (weighted_velocity .* cell_distance[1])...,
                (weighted_velocity .* cell_distance[2])...,
            )
            affine_momentum += inner_term
            particle_velocity += weighted_velocity
        end
        particle_affine_momentum = affine_momentum .* 4f0
        # Advect particle.
        particle_position = particle.position + particle_velocity * mpm.δt
        particle_position = clamp.(particle_position, 1, mpm.grid_resolution - 2)
        # Deformation gradient update.
        deformation_gradient = Mat2f0(I) + mpm.δt * particle_affine_momentum
        deformation_gradient *= particle.deformation_gradient

        mpm.particles[i] = Particle(
            particle_position,
            particle_velocity,
            particle_affine_momentum,
            deformation_gradient,
            particle.mass,
            particle.initial_volume,
        )
    end
end

function simulate!(mpm::MPM)
    # Reset grid.
    @inbounds for i in 1:mpm.grid_resolution, j in 1:mpm.grid_resolution
        mpm.grid[i, j] = Cell(Vec2f0(0f0, 0f0), 0f0)
    end
    # Particles-to-Grid: transfer data from particles to grid.
    particles_to_grid!(mpm)
    # Grid velocity update.
    grid_velocity_update!(mpm)
    # Grid-to-Particles: update particles based on the grid information.
    grid_to_particles!(mpm)
end

mutable struct MPMLayer <: Ray.Layer
    controller::Ray.OrthographicCameraController
    mpm::MPM
    simulate::Bool
end

function MPMLayer()
    Ray.init()
    controller = Ray.OrthographicCameraController(1280f0 / 720f0, true)
    mpm = MPM()
    MPMLayer(controller, mpm, false)
end

function draw_particles(
    mpm::MPM;
    particle_size::Float32 = 0.01f0, max_velocity::Float32 = 5f0,
    base_color = Point4f0(0.8f0, 0.3f0, 0.1f0, 1f0),
    top_color = Point4f0(1f0),
)
    for particle in mpm.particles
        world_position = (
            particle.position ./ Float32(mpm.grid_resolution) .- 0.5f0
        )
        particle_velocity = particle.velocity - Vec2f0(0f0, mpm.gravity)
        σ = clamp(norm(particle_velocity) / max_velocity, 0f0, 1f0)
        particle_color = (1 - σ) * base_color + σ * top_color

        Ray.draw_quad(
            Vec3f0(world_position..., 0f0), Vec2f0(particle_size),
            particle_color,
        )
    end
end

function Ray.on_update(cs::MPMLayer, timestep::Float64)
    timestep = Float32(timestep)

    Ray.OrthographicCameraModule.on_update(cs.controller, timestep)

    cs.simulate && simulate!(cs.mpm)

    Ray.Backend.set_clear_color(0.1, 0.1, 0.1, 1)
    Ray.Backend.clear()

    Ray.begin_scene(cs.controller.camera)
    draw_particles(cs.mpm; particle_size=0.01f0)
    Ray.end_scene()
end

function Ray.EngineCore.on_event(cs::MPMLayer, event::Ray.Event.MouseScrolled)
    Ray.OrthographicCameraModule.on_event(cs.controller, event)
end

function Ray.EngineCore.on_event(cs::MPMLayer, event::Ray.Event.KeyPressed)
    if event.key == GLFW.KEY_P
        cs.simulate = !cs.simulate
    end

    if event.key == GLFW.KEY_R
        grid, particles = reset_particles(cs.mpm.grid_resolution, 0.5f0, 16f0)
        cs.mpm.particles = particles
        cs.mpm.grid = grid
        # Scatter particle mass to the grid.
        particles_to_grid!(cs.mpm)
        # Estimate initial per-particle volume.
        estimate_volume!(cs.mpm)
    end
end

function Ray.EngineCore.on_event(cs::MPMLayer, event::Ray.Event.WindowResize)
    Ray.OrthographicCameraModule.on_event(cs.controller, event)
end

function Ray.on_imgui_render(cs::MPMLayer, timestep::Float64)
    CImGui.Begin("Neo-Hookean Elasticity")
    CImGui.Text("Grid resolution: $(cs.mpm.grid_resolution)x$(cs.mpm.grid_resolution)")
    CImGui.Text("Total particles: $(cs.mpm.num_particles)")

    CImGui.Text("[P] to play/pause simulation.")
    CImGui.Text("[R] to reset simulation.")
    CImGui.End()
end

function main()
    application = Ray.Application()
    Ray.push_layer(application.layer_stack, MPMLayer())
    application |> Ray.run
end
main()

end
