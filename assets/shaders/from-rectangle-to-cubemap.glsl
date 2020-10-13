#type vertex
#version 330 core

layout (location = 0) in vec3 a_Position;

uniform mat4 u_ViewProjection;

out vec3 v_LocalPos;

void main() {
    v_LocalPos = a_Position;
    gl_Position =  u_ViewProjection * vec4(v_LocalPos, 1.0);
}

#type fragment
#version 330 core

in vec3 v_LocalPos;

uniform sampler2D u_EquirectangularMap;

layout (location = 0) out vec4 frag_color;

const vec2 inv_atan = vec2(0.1591, 0.3183);

vec2 spherical_to_cartesian(vec3 v) {
    vec2 uv = vec2(atan(v.z, v.x), asin(v.y));
    uv *= inv_atan;
    uv += 0.5;
    return uv;
}

void main() {
    vec2 uv = spherical_to_cartesian(normalize(v_LocalPos));
    vec3 color = texture(u_EquirectangularMap, uv).rgb;
    frag_color = vec4(color, 1.0);
}
