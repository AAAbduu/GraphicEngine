#version 120

uniform int active_lights_n; // Number of active lights (< MG_MAX_LIGHT)
uniform vec3 scene_ambient; // Scene ambient light

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

uniform vec3 campos; // Camera position in world space

uniform sampler2D texture0;   // Texture
uniform samplerCube envmap;   // Environment map (cubemap)

varying vec3 f_position;      // camera space
varying vec3 f_viewDirection; // camera space
varying vec3 f_normal;        // camera space
varying vec2 f_texCoord;
varying vec3 f_positionw;    // world space
varying vec3 f_normalw;      // world space

float lambertFactor(in vec3 L, in vec3 N) {
	return max(dot(L, N), 0.0);
}

float specularFactor(const vec3 n, const vec3 l, const vec3 v, const float m) {
	// n es el vector normal
	// l es el vector de la luz
	// v es el vector que va a la cámara
	// m es el brillo del material
	// (theMaterial.shininess)
	//Modelo blin-phong
	vec3 h = normalize(l + v);
	if (dot(n, h) <= 0.0) return 0.0;
	return pow(dot(n, h), 4*m);
}

void main() {
	vec3 N = normalize(f_normal); //normal del vertice en el fragmento en coordenadas de camara

	vec3 V = normalize(f_viewDirection); //vector de la camara al vertice en coordenadas de camara

	vec3 L = vec3(0.0);

	//variables para la iluminacion
	vec3 difuso = vec3(0.0);
	vec3 i_especular = vec3(0.0);
	float factor_atenuacion = 1.0;

	vec4 f_color;

	f_color = vec4(0.0);


	//PARA TODAS LAS LUCES{
		for (int i = 0; i < active_lights_n; i++) {
			factor_atenuacion = 1.0;
			
			//CALCULAR EL VECTOR LUMINOSO
			//SI ES DIRECCIONAL
			if(theLights[i].position.w == 0.0){
				L = -theLights[i].position.xyz; //vector de la luz a la camara en coordenadas de camara
				L = normalize(L); //normalizar el vector
				float diffuse = lambertFactor(L, N); //calcular la componente difusa
				difuso += diffuse * theLights[i].diffuse; //calcular la componente difusa
				i_especular += specularFactor(N.xyz, L, V, theMaterial.shininess) * diffuse*theLights[i].specular; //calcular la componente especular

			}else{
				//posicional o spotlight
				L = (theLights[i].position.xyz - f_position.xyz);
				float distance = length(L);
				L = normalize(L);

				float denominador = (theLights[i].attenuation.x + theLights[i].attenuation.y * distance + theLights[i].attenuation.z * distance * distance);
				if(denominador > 0.0){
					factor_atenuacion = 1.0/denominador;
				}

				//si la luz es posicional
				if(theLights[i].cosCutOff==0){
					float diffuse = lambertFactor(L, N); //calcular la componente difusa
					difuso += diffuse * theLights[i].diffuse * factor_atenuacion; //calcular la componente difusa
					i_especular += specularFactor(N.xyz, L, V, theMaterial.shininess)* diffuse * theLights[i].specular * factor_atenuacion; //calcular la componente especular

				}
				//si la luz es foco
				if(theLights[i].cosCutOff>0){
					float cspot = dot((theLights[i].spotDir), -L);
					if(cspot > theLights[i].cosCutOff){
						float calculo = pow(cspot, theLights[i].exponent);
						float diffuse = lambertFactor(L, N); //calcular la componente difusa
						difuso += diffuse * theLights[i].diffuse* calculo; //calcular la componente difusa
						i_especular += specularFactor(N.xyz, L, V, theMaterial.shininess)* diffuse* theLights[i].specular * calculo; //calcular la componente especular
					}
				}
			}
		}


	//sumamos la componente difusa y especular
	vec3 I = vec3(0.0);
	I = normalize(campos - f_positionw);
	vec3 R = 2.0 * dot(f_normalw, I) * f_normalw - I;
	vec4 color_textura = texture2D(texture0, f_texCoord);
	vec4 cubeTex = textureCube(envmap, R);
	f_color += vec4((scene_ambient + difuso * theMaterial.diffuse) * color_textura.rgb * cubeTex.rgb,1.0);
	f_color += vec4(i_especular * theMaterial.specular,theMaterial.alpha);
	

	
	//f_color += vec4(i_especular * theMaterial.specular,1.0);

	gl_FragColor = f_color;
	//gl_FragColor = textureCube(envmap, f_normalw);

}