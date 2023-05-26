#version 120

attribute vec3 v_position;
attribute vec3 v_normal; 
attribute vec2 v_texCoord;
attribute vec3 v_TBN_t;
attribute vec3 v_TBN_b;

uniform mat4 modelToCameraMatrix;
uniform mat4 modelToWorldMatrix;
uniform mat4 cameraToClipMatrix;
uniform mat4 modelToClipMatrix;

uniform int active_lights_n; // Number of active lights (< MG_MAX_LIGHT)
uniform sampler2D albedo;
uniform sampler2D roughness;
uniform sampler2D normal; //ESPACIO TANGENTE, HAY QUE HACER LOS CALCULOS EN ESPACIO TANGENTE   

uniform struct light_t {
	vec4 position;    // Camera space
	vec3 diffuse;     // rgb
	vec3 specular;    // rgb
	vec3 attenuation; // (constant, lineal, quadratic)
	vec3 spotDir;     // Camera space
	float cosCutOff;  // cutOff cosine
	float exponent;
} theLights[4];     // MG_MAX_LIGHTS


varying vec2 f_texCoord;
varying vec3 f_viewDirection;     // tangent space
varying vec3 f_lightDirection[4]; // tangent space
varying vec3 f_spotDirection[4];  // tangent space

void main() {
	f_texCoord = v_texCoord;
	vec3 n = normalize(modelToCameraMatrix * vec4(v_normal, 0.0)).xyz;
	vec3 b = normalize(modelToCameraMatrix * vec4(v_TBN_b, 0.0)).xyz;
	vec3 t= normalize(modelToCameraMatrix * vec4(v_TBN_t, 0.0)).xyz;
	mat3 m_TBN = mat3(t, b, n); //calculo la matriz de cambio de base y se la paso al fragment shader
	m_TBN = transpose(m_TBN);

	vec3 f_position = (modelToCameraMatrix * vec4(v_position, 1.0)).xyz; // ahora en espacio de camara

	f_viewDirection = -f_position;
	for(int i = 0; i < active_lights_n; i++) { // calculo y le paso las direcciones de las luces al fragment shader
		f_spotDirection [i] = (m_TBN * theLights[i].spotDir);
		if(theLights[i].position.w == 0.0) { // directional light
			f_lightDirection[i] = (m_TBN * -theLights[i].position.xyz);
		} else { // point light
			f_lightDirection[i] = (m_TBN * (theLights[i].position.xyz - f_position)).xyz;
		}
	}
	f_viewDirection = (m_TBN * f_viewDirection);
	gl_Position = modelToClipMatrix * vec4(v_position, 1.0);
}