#version 120

// all attributes in model space
attribute vec3 v_position;
attribute vec3 v_normal; 

uniform mat4 modelToCameraMatrix;
uniform mat4 modelToWorldMatrix;
uniform mat4 cameraToClipMatrix;
uniform mat4 modelToClipMatrix;

uniform int active_lights_n; // Number of active lights (< MG_MAX_LIGHT)
uniform float roughness;     

uniform struct light_t {
	vec4 position;    // Camera space
	vec3 diffuse;     // rgb
	vec3 specular;    // rgb
	vec3 attenuation; // (constant, lineal, quadratic)
	vec3 spotDir;     // Camera space
	float cosCutOff;  // cutOff cosine
	float exponent;
} theLights[4];     // MG_MAX_LIGHTS


varying vec3 f_position;      // camera space // Posicion del vertice en coordenadas de camara
varying vec3 f_viewDirection; // camera space //vector que va desde la camara hasta el punto
varying vec3 f_normal;        // camera space // Normal del vertice en coordenadas de camara

void main(){
    gl_Position = modelToClipMatrix * vec4(v_position, 1.0);
    f_position = (modelToCameraMatrix * vec4(v_position, 1.0)).xyz;
    f_viewDirection = -f_position;
    f_normal = (modelToCameraMatrix * vec4(v_normal, 0.0)).xyz;
}