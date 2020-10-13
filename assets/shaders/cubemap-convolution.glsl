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

layout (location = 0) out vec4 frag_color;

const float PI = 3.14159265359;

void main() {
    vec3 normal = normalize(v_LocalPos);

    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 right = cross(up, normal);
    up = cross(normal, right);

    float sample_delta = 0.025;
    float nb_samples = 0.0;

    vec3 irradiance = vec3(0.0);

    for (float phi = 0.0; phi < 2.0 * PI; phi += sample_delta) {
        for (float theta = 0.0; theta < 0.5 * PI; theta += sample_delta) {
            float cos_theta = cos(theta);
            float sin_theta = sin(theta);
            /* Spherical to cartesian (in tangent space). */
            vec3 tangent_sample = vec3(
                sin_theta * cos(phi),
                sin_theta * sin(phi),
                cos_theta
            );
            vec3 sample_vec = (
                tangent_sample.x * right
                + tangent_sample.y * up
                + tangent_sample.z * normal
            );
            irradiance += (
                texture(u_EnvironmentMap, sample_vec).rgb
                * cos_theta * sin_theta
            );
            nb_samples++;
        }
    }

    irradiance *= PI / nb_samples;
    frag_color = vec4(irradiance, 1.0);
}
