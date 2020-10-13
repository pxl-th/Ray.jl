#type vertex
#version 330 core
layout (location = 0) in vec3 a_Position;

uniform mat4 u_Projection;
uniform mat4 u_View;

out vec3 v_LocalPosition;

void main()
{
    v_LocalPosition = a_Position;
    mat4 rot_view = mat4(mat3(u_View));
    vec4 clip_pos = u_Projection * rot_view * vec4(v_LocalPosition, 1.0);
    gl_Position = clip_pos.xyww;
}

#type fragment
#version 330 core

in vec3 v_LocalPosition;

uniform samplerCube u_EnvironmentMap;

out vec4 FragColor;

void main() {
    vec3 env_color = texture(u_EnvironmentMap, v_LocalPosition).rgb;
    /* env_color = env_color / (env_color + vec3(1.0)); */
    /* env_color = pow(env_color, vec3(1.0 / 2.2)); */
    FragColor = vec4(env_color, 1.0);
}
