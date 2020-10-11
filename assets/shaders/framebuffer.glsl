#type vertex
#version 330 core

layout (location = 0) in vec2 a_Position;
layout (location = 1) in vec2 a_TexCoord;

out vec2 v_TexCoord;

void main() {
    v_TexCoord = a_TexCoord;
    gl_Position = vec4(a_Position, 0.0, 1.0);
}

#type fragment
#version 330 core

in vec2 v_TexCoord;

uniform sampler2D u_ScreenTexture;

layout (location = 0) out vec4 frag_color;

void main() {
    vec3 color = texture(u_ScreenTexture, v_TexCoord).rgb;
    frag_color = vec4(color, 1.0);
}
