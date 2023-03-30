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

float specularFactor(const vec3 n, const vec3 l, const vec3 v, const float m) {
	// n es el vector normal
	// l es el vector de la luz
	// v es el vector que va a la cámara
	// m es el brillo del material
	// (theMaterial.shininess)
	float dotNL = dot(n, l); // 
	vec3 r = (2*dotNL)*n - l;
	r = normalize(r);		//IMportante normalizar el vector
	float dotProd = dot(r, v);
	return max(dotNL, 0.0) * pow(max(dotProd, 0.0), m);
}


void main() {

	vec3 L;
	// factor_difuso = n dot l (ya calculado)
	vec3 difuso = vec3(0.0);

	vec3 i_especular = vec3(0.0);

	float factor_atenuacion;
	
	f_color = vec4(scene_ambient,1.0);
	


	//CACULAR LA POSICION DEL VERTICE EN EL ESPACIO DEL MODELO DE LA CAMARA
	vec4 posEye4 = modelToCameraMatrix * vec4(v_position, 1.0);

	//PASAR LA NORMAL DEL VERTICE AL ESPACIO DE LA CAMARA
	vec4 normalEye4 = normalize((modelToCameraMatrix * vec4(v_normal, 0.0)));

	vec3 vE = normalize(-posEye4.xyz); // vector de la camara al vertice

	//PARA TODAS LAS LUCES{
		for (int i = 0; i < active_lights_n; i++) {
			factor_atenuacion = 1.0;
			
			//CALCULAR EL VECTOR LUMINOSO
		//SI ES DIRECCIONAL
			if(theLights[i].position.w == 0.0){
				L = -1.0 * normalize(theLights[i].position.xyz);
				difuso += lambertFactor(L, normalEye4.xyz) * theMaterial.diffuse * theLights[i].diffuse ; //calcular la componente difusa
				i_especular += specularFactor(normalEye4.xyz, L, vE, theMaterial.shininess) * theMaterial.specular * theLights[i].specular;
			}else{
				//posicional o spotlight
				L = (theLights[i].position.xyz - posEye4.xyz);
				float distance = length(L);
				L = normalize(L);
				
				float denominador = (theLights[i].attenuation.x + theLights[i].attenuation.y * distance + theLights[i].attenuation.z * distance * distance);
				if(denominador > 0.0){
					factor_atenuacion = 1.0/denominador;
				}

				//si la luz es posicional
				if(theLights[i].cosCutOff == 0.0){
					difuso += lambertFactor(L, normalEye4.xyz) * theMaterial.diffuse * theLights[i].diffuse * factor_atenuacion; //calcular la componente difusa
					i_especular += specularFactor(normalEye4.xyz, L, vE, theMaterial.shininess) * theMaterial.specular * theLights[i].specular * factor_atenuacion;

				}
				//si la luz es foco
				if(theLights[i].cosCutOff > 0.0){
					float cspot = dot((theLights[i].spotDir), -L);
					if(cspot > theLights[i].cosCutOff){
						float calculo = pow(cspot, theLights[i].exponent);
						difuso += lambertFactor(L, normalEye4.xyz) * theMaterial.diffuse * theLights[i].diffuse * calculo; //calcular la componente difusa
						i_especular += specularFactor(normalEye4.xyz, L, vE, theMaterial.shininess) * theMaterial.specular * theLights[i].specular * calculo; //calcular la componente especular
					}


				}
			}
				
		
		//difuso += lambertFactor(L, v_normal) * theMaterial.diffuse * theLights[i].diffuse * factor_atenuacion; //calcular la componente difusa
		//i_especular += specularFactor(normalEye4.xyz, L, vE, theMaterial.shininess) * theMaterial.specular * theLights[i].specular * factor_atenuacion; //calcular la componente especular

	}

	//sumamos la componente difusa y especular
	f_color += vec4(difuso,1.0);
	f_color += vec4(i_especular,1.0);

	f_texCoord = v_texCoord;
	gl_Position = modelToClipMatrix * vec4(v_position, 1);
}
