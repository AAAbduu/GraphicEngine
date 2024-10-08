#version 120

attribute vec3 v_position;
attribute vec3 v_normal;
attribute vec2 v_texCoord;

uniform int active_lights_n; // Number of active lights (< MG_MAX_LIGHT)

uniform mat4 modelToCameraMatrix;
uniform mat4 cameraToClipMatrix;
uniform mat4 modelToWorldMatrix;
uniform mat4 modelToClipMatrix;

varying vec3 f_position;      // camera space // Posicion del vertice en coordenadas de camara
varying vec3 f_viewDirection; // camera space //vector que va desde la camara hasta el punto
varying vec3 f_normal;        // camera space // Normal del vertice en coordenadas de camara
varying vec2 f_texCoord;		 // texture coordinates
//PASAR VECTORES SIN NORMALIZAR
void main() {
	f_position = (modelToCameraMatrix * vec4(v_position, 1.0)).xyz;
  	f_viewDirection = -f_position;
  	f_normal = (modelToCameraMatrix * vec4(v_normal, 0.0)).xyz;
  	f_texCoord = v_texCoord;
	gl_Position = modelToClipMatrix * vec4(v_position, 1.0);
}
