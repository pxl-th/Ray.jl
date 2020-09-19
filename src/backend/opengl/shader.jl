struct Shader <: Abstractions.Shader
    id::UInt32
end

function Shader(vertex_shader::String, fragment_shader::String)
    shader_ids = [
        create_shader(vertex_shader, GL_VERTEX_SHADER),
        create_shader(fragment_shader, GL_FRAGMENT_SHADER),]
    program = create_program(shader_ids)
    glDeleteShader.(shader_ids)
    Shader(program)
end

bind(shader::Shader) = glUseProgram(shader.id)
unbind(::Shader) = glUseProgram(0)
delete(shader::Shader) = glDeleteProgram(shader.id)

function validate_shader(shader_id::UInt32, shader::String)
    success = @ref glGetShaderiv(shader_id, GL_COMPILE_STATUS, RepInt32)
    success == GL_TRUE && return

    error_token = "ERROR: "
    error_log = getInfoLog(shader_id)
    error_log_lines = map(
        s -> strip(Base.replace(s, error_token => "")),
        split(error_log, error_token, keepempty=false))
    error("Failed to compile shader: \n $error_log_lines")
end

function getInfoLog(object::UInt32)::String
    # Return the info log for object, whether it be a shader or a program.
    is_shader = glIsShader(object)
    getiv = is_shader == GL_TRUE ? glGetShaderiv : glGetProgramiv
    getInfo = is_shader == GL_TRUE ? glGetShaderInfoLog : glGetProgramInfoLog
    # Get the maximum possible length for the descriptive error message.
    max_message_length = @ref getiv(object, GL_INFO_LOG_LENGTH, RepInt32)
    # Return the text of the message if there is any.
    max_message_length == 0 && return ""
    message_buffer = zeros(UInt8, max_message_length)
    message_length = @ref getInfo(object, max_message_length, RepInt64, message_buffer)
    unsafe_string(Base.pointer(message_buffer), message_length)
end


function create_shader(shader::String, type::UInt32)::UInt32
    shader_id = glCreateShader(type)
    shader_id == 0 && error("Failed to create shader of type [$type]")

    gl_char_shader = pointer([convert(Ptr{UInt8}, pointer(shader))])
    gl_char_shader = convert(Ptr{UInt8}, gl_char_shader)
    glShaderSource(shader_id, 1, gl_char_shader, C_NULL)

    glCompileShader(shader_id)
    validate_shader(shader_id, shader)

    shader_id
end

function create_program(shaders::Vector{UInt32})::UInt32
    program_id = glCreateProgram()
    program_id == 0 && error("Failed to create shader program")

    for shader in shaders
        glAttachShader(program_id, shader)
    end
    glLinkProgram(program_id)

    success = @ref glGetProgramiv(program_id, GL_LINK_STATUS, RepInt32)
    if success == GL_FALSE
        glDeleteProgram(program_id)
        error("Failed to link shader program.\n$(getInfoLog(program_id))")
    end

    program_id
end
