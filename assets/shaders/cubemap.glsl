#type vertex
#version 330 core

layout (location = 0) in vec3 a_Position;

uniform mat4 u_ViewProjection;

out vec3 v_FragUV;

void main() {
    v_FragUV = a_Position;
    gl_Position = (u_ViewProjection * vec4(a_Position, 1.0)).xyww;
}

#type fragment
#version 330 core

in vec3 v_FragUV;

uniform samplerCube u_Cubemap;

out vec4 frag_color;

void main() {
    frag_color = texture(u_Cubemap, v_FragUV);
}
