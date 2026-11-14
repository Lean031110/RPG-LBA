shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
// Viento caribeño: balanceo por altura con fase derivada de la posición del
// mundo (cada planta se mueve distinto sin materiales por instancia).
// Compatibility Renderer seguro: solo desplazamiento de vértices.
uniform vec4 base_color : source_color = vec4(0.16, 0.34, 0.15, 1.0);
uniform float strength : hint_range(0.0, 0.3) = 0.05;
uniform float speed : hint_range(0.2, 4.0) = 1.6;

void vertex() {
	vec3 world_origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float phase = TIME * speed + (world_origin.x + world_origin.z) * 0.35;
	float mask = smoothstep(0.05, 1.4, VERTEX.y);
	VERTEX.x += sin(phase) * strength * mask;
	VERTEX.z += cos(phase * 0.77) * strength * 0.6 * mask;
}

void fragment() {
	ALBEDO = base_color.rgb;
	ROUGHNESS = 0.95;
}
