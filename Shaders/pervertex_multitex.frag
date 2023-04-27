#version 120

varying vec4 f_color;
varying vec2 f_texCoord;

uniform sampler2D texture0;
uniform sampler2D texture1;

uniform float uCloudOffset; // The offset of the cloud texture

void main() {

	// The final color must be a linear combination of both
	// textures with a factor of 0.5, e.g:
	//
	// color = 0.5 * color_of_texture0 + 0.5 * color_of_texture1

	// Aplicamos el offset a la textura de las nubes
	vec2 texture1Offset = f_texCoord + vec2(uCloudOffset, 0.0);

	vec4 color_textura = 0.65 * texture2D(texture0, f_texCoord) + 0.35 * texture2D(texture1, texture1Offset);


	gl_FragColor = color_textura * f_color; //como lo hacemos en el fragment shader
}
