#version 120

uniform mat4 modelToCameraMatrix;
uniform mat4 modelToWorldMatrix;
uniform mat4 cameraToClipMatrix;
uniform mat4 modelToClipMatrix;

uniform int active_lights_n; // Number of active lights (< MG_MAX_LIGHT)
uniform vec3 scene_ambient;
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

uniform struct material_t {
	vec3  diffuse;
	vec3  specular;
	float alpha;
	float shininess;
} theMaterial;

varying vec2 f_texCoord;
varying vec3 f_viewDirection;     // tangent space
varying vec3 f_lightDirection[4]; // tangent space
varying vec3 f_spotDirection[4];  // tangent space

const float PI = 3.1415926535897932384626433832795;

/**
 * @brief La funcion de reflectancia de Fresnel
 * @param L VEctor direccion de la luz
 * @param H Vector medio
 * @param fRM Factor de reflectancia de Fresnel del material
 * @return termino F de la ecuacion de Cook Torrance
 */
vec3 F(vec3 l, vec3 h, vec3 fRM){
	float lDotH = max(dot(l, h), 0.0);
	return fRM + (1.0 - fRM) * pow(1.0 - lDotH, 5.0);
}


/**
* @brief La funcion geométrica de Cook Torrance
* @param N Vector normal
* @param H Vector medio
* @param V Vector direccion de la camara
* @param L Vector direccion de la luz
* @return termino G de la ecuacion de Cook Torrance
*/
float G(vec3 n, vec3 h, vec3 v, vec3 l){
	float vDoth = max(dot(v, h), 0.0);
	float nDoth = max(dot(n, h), 0.0);
	float nDotv = max(dot(n, v), 0.0);
	float nDotl = max(dot(n, l), 0.0);
	float calculo = 2.0 * (nDoth*nDotv)/(vDoth + 0.001);
	float m = min(1.0, calculo);
	return min(m, 2.0 * (nDoth*nDotl)/(vDoth + 0.001)); //evitar division por 0
}


/**
* @brief La funcion de distribucion de Cook Torrance
* @param N Vector normal
* @param H Vector medio
* @param r Rugosidad del material
*/
float D(vec3 n, vec3 h, float r){
	float hDotn = max(dot(h, n), 0.0);
	float r2 = r * r;
	float hDotn2 = hDotn * hDotn;

	float numExp = hDotn2 - 1.0;
	float denExp = r2 * hDotn2;

	return exp(numExp/denExp)/((PI * r2 * hDotn2 * hDotn2) + 0.001); //evitar division por 0

}

vec3 fSpecular (vec3 n, vec3 v, vec3 l, vec3 h, float r, vec3 fRM){
	float nDotl = dot(n, l);
	float nDotv = dot(n, v);
	vec3 num = D(n, h, r) * F(l, h, fRM) * G(n, h, v, l);
	float den = 4.0 * nDotl * nDotv;
	return num/(den + 0.001); //evitar division por 0

}


void main(){
	vec3 N = normalize(texture2D(normal, f_texCoord).xyz);
	vec3 V = normalize(f_viewDirection);
	vec3 L = vec3(0.0);
	vec3 fr = vec3(0.0);
	
	float roughness = texture2D(roughness, f_texCoord).r; //cogemos el roughness del canal rojo de la textura

	vec3 albedo = texture2D(albedo, f_texCoord).rgb; //cogemos el albedo de la textura
	vec3 fRFresnel = theMaterial.specular;

	vec3 fdifuso = albedo/PI; //esto es siempre igual según la formula del enunciado

	vec3 k_s = fRFresnel;
	vec3 k_d = vec3(1.0) - k_s;

	vec3 i_especular = vec3(0.0);
	float factor_atenuacion = 1.0;

	vec3 intensidadLuz = vec3(0.0);


	for (int i = 0; i < active_lights_n; i++) {
			factor_atenuacion = 1.0;
			
			//CALCULAR EL VECTOR LUMINOSO
			//SI ES DIRECCIONAL
			if(theLights[i].position.w == 0.0){
				L = normalize(f_lightDirection[i]); //normalizar el vector
				vec3 H = normalize(L + V); //calcular el vector medio
				i_especular = fSpecular(N, V, L, H, roughness, fRFresnel); //calcular la componente especular

			}else{
				//posicional o spotlight
				L = f_lightDirection[i];
				float distance = length(L);
				L = normalize(L);

				float denominador = (theLights[i].attenuation.x + theLights[i].attenuation.y * distance + theLights[i].attenuation.z * distance * distance);
				if(denominador > 0.0){
					factor_atenuacion = 1.0/denominador;
				}

				//si la luz es posicional
				if(theLights[i].cosCutOff==0){
					vec3 H = normalize(L + V); //calcular el vector medio
					i_especular = fSpecular(N, V, L, H, roughness, fRFresnel); //calcular la componente especular

				}
				//si la luz es foco
				if(theLights[i].cosCutOff>0){
					float cspot = dot((theLights[i].spotDir), -L);
					if(cspot > theLights[i].cosCutOff){
						float calculo = pow(cspot, theLights[i].exponent);
						vec3 H = normalize(L + V); //calcular el vector medio
						i_especular = fSpecular(N, V, L, H, roughness, fRFresnel) ; //calcular la componente especular
					}
				}
			}

			float nDotl = max(dot(N, L), 0.0);


			fr += (k_d * fdifuso + k_s * i_especular)* theLights[i].diffuse  * nDotl * factor_atenuacion;

		}

	fr+=scene_ambient;
    gl_FragColor = vec4(fr, 1.0);
}