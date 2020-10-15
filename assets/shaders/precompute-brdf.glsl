#type vertex
#version 330 core

layout (location = 0) in vec2 a_Position;
layout (location = 1) in vec2 a_TexCoords;

out vec2 v_TexCoords;

void main() {
    v_TexCoords = a_TexCoords;
    gl_Position = vec4(a_Position, 0.0, 1.0);
}

#type fragment
#version 330 core

in vec2 v_TexCoords;

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

float geometry_schlick_ggx(float ndotv, float roughness) {
    float k = (roughness * roughness) / 2.0;

    float nom = ndotv;
    float denom = ndotv * (1.0 - k) + k;
    return nom / denom;
}

float geometry_smith(vec3 n, vec3 v, vec3 l, float roughness) {
    float ndotv = max(0.0, dot(n, v));
    float ndotl = max(0.0, dot(n, l));

    float ggx1 = geometry_schlick_ggx(ndotl, roughness);
    float ggx2 = geometry_schlick_ggx(ndotv, roughness);

    return ggx1 * ggx2;
}

vec2 integrate_brdf(float n_dot_v, float roughness) {
    vec3 v = vec3(sqrt(1.0 - n_dot_v * n_dot_v), 0.0, n_dot_v);
    vec3 n = vec3(0.0, 0.0, 1.0);

    float a = 0.0;
    float b = 0.0;

    const uint sample_count = 1024u;
    for (uint i = 0u; i< sample_count; i++) {
        /* Generate sample vector biased towards preferred alignment direction
         * (importance sampling). */
        vec2 xi = hammersley(i, sample_count);
        vec3 halfway = importance_sample_ggx(xi, n, roughness);
        vec3 l = normalize(2.0 * dot(v, halfway) * halfway - v);

        float n_dot_l = max(0.0, l.z);
        float n_dot_h = max(0.0, halfway.z);
        float v_dot_h = max(0.0, dot(v, halfway));

        if (n_dot_l > 0.0) {
            float g = geometry_smith(n, v, l, roughness);
            float g_vis = (g * v_dot_h) / (n_dot_h * n_dot_v);
            float fc = pow(1.0 - v_dot_h, 5.0);

            a += (1.0 - fc) * g_vis;
            b += fc * g_vis;
        }
    }
    a /= float(sample_count);
    b /= float(sample_count);
    return vec2(a, b);
}

void main() {
    vec2 brdf = integrate_brdf(v_TexCoords.x, v_TexCoords.y);
    frag_color = vec4(brdf, 0.0, 1.0);
}
