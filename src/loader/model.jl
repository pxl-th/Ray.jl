struct Material
    albedo::Backend.Texture2D
    metallic::Backend.Texture2D
    roughness::Backend.Texture2D
    normal::Backend.Texture2D
    ao::Backend.Texture2D
end

struct ModelVAO
    vao::Backend.VertexArray
    material_idx::UInt32
end

struct ModelNode
    meshes::Vector{ModelVAO}
    children::Vector{ModelNode}
end

struct Model
    node::ModelNode
    materials::Dict{UInt32, Material}
end

function upload_uniform(
    shader::Ray.Backend.Shader, name::String,
    material::Material, slot::Integer = 0,
)
    Ray.Backend.bind(material.albedo, slot)
    Ray.Backend.bind(material.metallic, slot + 1)
    Ray.Backend.bind(material.roughness, slot + 2)
    Ray.Backend.bind(material.normal, slot + 3)
    Ray.Backend.bind(material.ao, slot + 4)

    Ray.Backend.upload_uniform(shader, "$name.albedo", slot)
    Ray.Backend.upload_uniform(shader, "$name.metallic", slot + 1)
    Ray.Backend.upload_uniform(shader, "$name.roughness", slot + 2)
    Ray.Backend.upload_uniform(shader, "$name.normal", slot + 3)
    Ray.Backend.upload_uniform(shader, "$name.ao", slot + 4)
end

function draw(
    mvao::ModelVAO, shader::Backend.Shader,
    name::String, materials::Dict{UInt32, Material},
)
    upload_uniform(shader, name, materials[mvao.material_idx])
    mvao.vao |> Backend.bind
    mvao.vao |> Backend.draw_indexed
end

function draw(
    node::ModelNode, shader::Backend.Shader,
    name::String, materials::Dict{UInt32, Material},
)
    for mesh in node.meshes
        draw(mesh, shader, name, materials)
    end
    for child in node.children
        draw(child, shader, name, materials)
    end
end

function draw(
    model::Model, shader::Backend.Shader, name::String,
    view_projection::Mat4f0, transform::Mat4f0 = Mat4f0(I),
)
    Backend.upload_uniform(shader, "u_ViewProjection", view_projection)
    Backend.upload_uniform(shader, "u_Model", transform)
    draw(model.node, shader, name, model.materials)
end

function load(
    path::String, flags::UInt32 = UInt32(0), default_flags::Bool = true,
)
    scene = Assimp.load(path, flags, default_flags=default_flags)
    model = to_model(scene.node)
    materials = convert_materials(scene.materials)
    Model(model, materials)
end

to_model(node::Assimp.Node) =
    ModelNode(map(to_vao, node.meshes), map(to_model, node.children))

function convert_materials(materials::Dict{UInt32, Assimp.Material})
    # TODO do not convert unused materials
    # TODO remove empty nodes (or do not render them)
    texture_types = [
        Assimp.aiTextureType_DIFFUSE,
        Assimp.aiTextureType_METALNESS,
        Assimp.aiTextureType_REFLECTION,
        Assimp.aiTextureType_NORMALS,
        Assimp.aiTextureType_AMBIENT_OCCLUSION,
    ]
    converted_materials = Dict{UInt32, Material}()
    for (i, a_material) in materials
        textures = []
        for type in texture_types
            if type in keys(a_material.textures)
                @info "Using existing texture for type $type"
                a_texture = a_material.textures[type][1]
                @info "Texture $(typeof(a_texture))"
                height, width = a_texture.data |> size
                @info "Texture of type $(typeof(a_texture.data))"
                texture = Backend.Texture2D(a_texture.data, width, height)
            else
                @info "No texture with type [$type]"
                texture = Backend.Texture2D(
                    1, 1, internal_format=GL_RGB8, data_format=GL_RGB,
                )
                Backend.set_data!(texture, UInt8[0xff, 0xff, 0xff], 3)
            end
            push!(textures, texture)
        end
        converted_materials[i] = Material(textures...)
    end
    @info "Materials under [$(keys(converted_materials))] keys"
    converted_materials
end

function to_vao(mmesh::Assimp.MetaMesh)
    # Determine layout.
    layout_order = ["a_Position", "a_TexCoord", "a_Normal"]
    layout = Dict{String, Abstractions.BufferElement}()
    properties = Dict{String, Any}()
    total_elements = 0
    element_length = 0

    for property in propertynames(mmesh.mesh)
        data = getproperty(mmesh.mesh, property)
        data_el_length = data |> eltype |> length
        total_elements = data |> length
        element_length += data_el_length

        be = BufferElement(property, data_el_length)
        properties[be.name] = data
        layout[be.name] = be
    end
    # TODO handle missing layout parts
    vb_layout = Abstractions.BufferLayout([
        layout[order] for order in layout_order
    ])
    @info "VB Layout $vb_layout"
    # Pack data to buffer.
    buffer = Vector{Float32}(undef, total_elements * element_length)
    nb_packed = 1
    @inbounds for i in 1:total_elements
        for order in layout_order
            for j in properties[order][i]
                buffer[nb_packed] = j
                nb_packed += 1
            end
        end
    end
    @assert nb_packed - 1 == length(buffer)
    # Pack indices to buffer.
    face_indices = mmesh.mesh |> faces
    face_length = face_indices |> eltype |> length
    primitive = to_gl_primitive(face_length)

    indices = Vector{UInt32}(undef, length(face_indices) * face_length)
    nb_packed = 1
    @inbounds for face in face_indices
        for i in face
            indices[nb_packed] = i
            nb_packed += 1
        end
    end
    @assert nb_packed - 1 == length(indices)
    # Create VAO.
    va = Backend.VertexArray()
    vb = Backend.VertexBuffer(buffer, buffer |> sizeof)
    ib = Backend.IndexBuffer(indices, primitive_type=primitive)

    Backend.set_layout(vb, vb_layout)
    Backend.add_vertex_buffer(va, vb)
    Backend.set_index_buffer(va, ib)

    ModelVAO(va, mmesh.material_idx)
end

to_gl_primitive(face_length::Integer) = Dict(
    1 => GL_POINTS, 2 => GL_LINES, 3 => GL_TRIANGLES, 4 => GL_QUADS,
)[face_length]

function BufferElement(property::Symbol, element_length::Integer)
    name_mapping = Dict(
        :position => "a_Position",
        :normals => "a_Normal",
        :uvw => "a_TexCoord",
    )
    type_mapping = Dict(
        1 => Point1f0,
        2 => Point2f0,
        3 => Point3f0,
        4 => Point4f0,
    )
    !(property in keys(name_mapping)) && error(
        "Unsupported property [$property]. Supported properties are [$(keys(name_mapping))].",
    )
    !(element_length in keys(type_mapping)) && error(
        "Unsupported type of length [$element_length]. Supported lengths are [$(keys(type_mapping))].",
    )
    Abstractions.BufferElement(type_mapping[element_length], name_mapping[property])
end
