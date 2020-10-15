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

uniform samplerCube u_EnvironmentMap;
uniform float u_Roughness;

layout (location = 0) out vec4 frag_color;

const float PI = 3.14159265359;

/* Mirrors a decibal binary representation around its decimal point. */
float radical_inverse_vdc(uint bits) {
    bits = (bits << 16u) | (bits >> 16u);
    bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
    bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
    bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
    bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
    return float(bits) * 2.3283064365386963e-10; // 0x100000000
}

float distribution_ggx(vec3 n, vec3 halfway, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;
    float n_dot_h = max(0.0, dot(n, halfway));
    float n_dot_h2 = n_dot_h * n_dot_h;

    float nom = a2;
    float denom = (n_dot_h2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return nom / denom;
}

/* Generates low-discrepancy sample i of the total sample set of size N. */
vec2 hammersley(uint i, uint n) {
    return vec2(float(i) / float(n), radical_inverse_vdc(i));
}

/* Sample vector oriented around expected microsurface's halfway vector
 * based on roughness and low-discrepancy sequence xi. */
vec3 importance_sample_ggx(vec2 xi, vec3 n, float roughness) {
    float a = roughness * roughness;

    float phi = 2.0 * PI * xi.x;
    float cos_theta = sqrt((1.0 - xi.y) / (1.0 + (a * a - 1.0) * xi.y));
    float sin_theta = sqrt(1.0 - cos_theta * cos_theta);

    /* Transform halfway vector from spherical to cartesian coordinates. */
    vec3 halfway = vec3(cos(phi) * sin_theta, sin(phi) * sin_theta, cos_theta);
    /* Transform from tangent to world space. */
    vec3 up = abs(n.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    vec3 tangent = normalize(cross(up, n));
    vec3 bitangent = cross(n, tangent);

    vec3 sample_vec = tangent * halfway.x + bitangent * halfway.y + n * halfway.z;
    return normalize(sample_vec);
}

void main() {
    vec3 n = normalize(v_LocalPos);
    vec3 r = n;
    vec3 v = r;

    const uint sample_count = 1024u;
    float total_weight = 0.0;
    vec3 prefiltered_color = vec3(0.0);
    float resolution = 512.0; // Per face env cubemap resolution.

    for (uint i = 0u; i < sample_count; i++) {
        vec2 xi = hammersley(i, sample_count);
        vec3 halfway = importance_sample_ggx(xi, n, u_Roughness);
        vec3 l = normalize(2.0 * dot(v, halfway) * halfway - v);

        float n_dot_l = max(0.0, dot(n, l));
        if (n_dot_l > 0.0) {
            /* Sample environment's mip level based on roughness/pdf. */
            float d = distribution_ggx(n, halfway, u_Roughness);
            float n_dot_h = max(0.0, dot(n, halfway));
            float h_dot_v = max(0.0, dot(halfway, v));
            float pdf = d * n_dot_h / (4.0 * h_dot_v) + 0.0001;

            float sa_texel = 4.0 * PI / (6.0 * resolution * resolution);
            float sa_sample = 1.0 / (float(sample_count) * pdf + 0.0001);

            float mip_level = u_Roughness == 0.0 ? 0.0 : 0.5 * log2(sa_sample / sa_texel);

            prefiltered_color += textureLod(u_EnvironmentMap, l, mip_level).rgb * n_dot_l;
            total_weight += n_dot_l;
        }
    }

    prefiltered_color /= total_weight;
    frag_color = vec4(prefiltered_color, 1.0);
}
