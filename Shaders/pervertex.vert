#version 120

uniform mat4 modelToCameraMatrix;
uniform mat4 cameraToClipMatrix;
uniform mat4 modelToWorldMatrix;
uniform mat4 modelToClipMatrix;

uniform int active_lights_n; // Number of active lights (< MG_MAX_LIGHT)
uniform vec3 scene_ambient;  // rgb

uniform struct light_t {
	vec4 position;    // Camera space
	vec3 diffuse;     // rgb
	vec3 specular;    // rgb
	vec3 attenuation; // (constant, lineal, quadratic)
	vec3 spotDir;     // Camera space
	float cosCutOff;  // cutOff cosine
	float exponent;
} theLights[4];     // MG_MAX_LIGHTS

uniform struct material_t {
	vec3  diffuse;
	vec3  specular;
	float alpha;
	float shininess;
} theMaterial;

attribute vec3 v_position; // Model space
attribute vec3 v_normal;   // Model space
attribute vec2 v_texCoord;

varying vec4 f_color;
varying vec2 f_texCoord;

float lambertFactor(in vec3 L, in vec3 N) {
	return max(dot(L, N), 0.0);
}


void main() {

	vec3 L;

	vec3 difuso = vec3(0.0);
	vec3 especular = vec3(0.0);

	

	f_color = vec4(scene_ambient,1.0);
	f_texCoord = v_texCoord;


	//CACULAR LA POSICION DEL VERTICE EN EL ESPACIO DEL MODELO DE LA CAMARA
	vec4 posEye4 = modelToCameraMatrix * vec4(v_position, 1.0);

	//PASAR LA NORMAL DEL VERTICE AL ESPACIO DE LA CAMARA
	vec4 normalEye4 = normalize((modelToCameraMatrix * vec4(v_normal, 0.0)));

	//PARA TODAS LAS LUCES{
		for (int i = 0; i < active_lights_n; i++) {
			
			//CALCULAR EL VECTOR LUMINOSO
		//SI ES DIRECCIONAL
			if(theLights[i].position.w == 0.0)
				L = normalize(-theLights[i].position.xyz);
			else
				//posicional o spotlight
				L = normalize(theLights[i].position.xyz - posEye4.xyz);

		//calcular la componente especular

		difuso += lambertFactor(L, v_normal) * theMaterial.diffuse * theLights[i].diffuse;
	}

	//CAlcula y asigna la componente difusa
	f_color = vec4(scene_ambient + difuso, 1.0);
	gl_Position = modelToClipMatrix * vec4(v_position, 1);
}
