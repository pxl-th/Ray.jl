#type vertex
#version 330 core
layout (location = 0) in vec3 a_Position;
layout (location = 1) in vec2 a_TexCoord;
layout (location = 2) in vec3 a_Normal;

uniform mat4 u_Model;
uniform mat4 u_ViewProjection;

out vec2 v_TexCoord;
out vec3 v_WorldPos;
out vec3 v_Normal;

void main() {
    v_TexCoord = a_TexCoord;
    v_WorldPos = vec3(u_Model * vec4(a_Position, 1.0));
    v_Normal = mat3(u_Model) * a_Normal;
    gl_Position = u_ViewProjection * vec4(v_WorldPos, 1.0);
}

#type fragment
#version 330 core

struct Material {
    sampler2D albedo;
    sampler2D metallic;
    sampler2D roughness;
    sampler2D normal;
    sampler2D ao;
};

in vec2 v_TexCoord;
in vec3 v_WorldPos;
in vec3 v_Normal;

uniform vec3 u_CamPos;
uniform Material u_Material;

uniform samplerCube u_IrradianceMap;
uniform samplerCube u_PrefilterMap;
uniform sampler2D u_BrdfLUT;
uniform vec3 u_LightPos[4];
uniform vec3 u_LightColors[4];

layout (location = 0) out vec4 frag_color;

const float PI = 3.14159265359;

vec3 fresnel_schlick(float cos_theta, vec3 f0) {
    return f0 + (1.0 - f0) * pow(1.0 - cos_theta, 5.0);
}

vec3 fresnel_schlick_roughness(float cos_theta, vec3 f0, float roughness) {
    return (
        f0 + (max(vec3(1.0 - roughness), f0) - f0)
        * pow(1.0 - cos_theta, 5.0)
    );
}

float distribution_ggx(vec3 n, vec3 h, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;
    float ndh = max(0.0, dot(n, h));
    float ndh2 = ndh * ndh;

    float nom = a2;
    float denom = (ndh2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return nom / max(0.001, denom);
}

float geometry_schlick_ggx(float ndotv, float roughness) {
    float r = (roughness + 1.0);
    float k = (r * r) / 8.0;

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

vec3 get_normal() {
    vec3 tangentNormal = texture(u_Material.normal, v_TexCoord).xyz * 2.0 - 1.0;

    vec3 Q1 = dFdx(v_WorldPos);
    vec3 Q2 = dFdy(v_WorldPos);
    vec2 st1 = dFdx(v_TexCoord);
    vec2 st2 = dFdy(v_TexCoord);

    vec3 N = normalize(v_Normal);
    vec3 T = normalize(Q1 * st2.t - Q2 * st1.t);
    vec3 B = -normalize(cross(N, T));
    mat3 TBN = mat3(T, B, N);

    return normalize(TBN * tangentNormal);
}

void main() {
    vec3 albedo = pow(texture(u_Material.albedo, v_TexCoord).rgb, vec3(2.2));
    vec3 normal = get_normal();
    float metallic = texture(u_Material.metallic, v_TexCoord).r;
    float roughness = texture(u_Material.roughness, v_TexCoord).r;
    float ao = texture(u_Material.ao, v_TexCoord).r;

    vec3 n = normal;
    vec3 v = normalize(u_CamPos - v_WorldPos); // Viewer direction.

    vec3 f0 = vec3(0.04);
    f0 = mix(f0, albedo, metallic);

    vec3 f = fresnel_schlick_roughness(max(0.0, dot(n, v)), f0, roughness);

    /* Specular component. */
    vec3 r = reflect(-v, n);
    const float max_reflection_lod = 4.0;
    vec3 prefiltered_color = textureLod(
        u_PrefilterMap, r, roughness * max_reflection_lod
    ).rgb;
    vec2 brdf = texture(u_BrdfLUT, vec2(max(0.0, dot(n, v)), roughness)).rg;
    vec3 specular = prefiltered_color * (f * brdf.x + brdf.y);

    /* Reflectance equation. */
    vec3 Lo = vec3(0.0);
    for (int i = 0; i < 4; i++) {
        vec3 l = u_LightPos[i] - v_WorldPos;
        float dist = length(l);
        l = normalize(l); // Light direciton.
        vec3 h = normalize(v + l);

        float attenuation = 1.0 / (dist * dist);
        vec3 radiance = u_LightColors[i] * attenuation;

        /* Calculate Cook-Torrance BRDF. */
        vec3 f = fresnel_schlick(clamp(dot(h, v), 0.0, 1.0), f0);
        float ndf = distribution_ggx(n, h, roughness);
        float g = geometry_smith(n, v, l, roughness);

        vec3 nominator = f * ndf * g;
        float denominator = 4 * max(0.0, dot(n, v)) * max(0.0, dot(n, l));
        vec3 specular = nominator / max(0.001, denominator);

        vec3 ks = f;
        vec3 kd = 1.0 - ks;
        kd *= 1.0 - metallic;

        float ndotl = max(0.0, dot(n, l));
        Lo += (kd * albedo / PI + specular) * radiance * ndotl;
    }

    vec3 ks = f;
    vec3 kd = 1.0 - ks;
    kd *= 1.0 - metallic;
    vec3 irradiance = texture(u_IrradianceMap, n).rgb;
    vec3 ambient = (irradiance * albedo * kd + specular) * ao;
    /* vec3 ambient = vec3(0.03) * albedo * ao; */

    vec3 color = ambient + Lo;
    /* HDR tonemapping. */
    color = color / (color + vec3(1.0));
    /* Gamma correction. */
    color = pow(color, vec3(1.0 / 2.2));

    frag_color = vec4(color, 1.0);
}
