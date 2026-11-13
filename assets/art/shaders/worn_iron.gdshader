shader_type spatial;
// Hierro forjado envejecido (faroles, ruedas de la carreta, herrajes):
// óxido procedimental por value-noise que devora el metal y sube la rugosidad.
// Compat Renderer: ruido barato en fragment, sin texturas.
uniform vec4 iron_color : source_color = vec4(0.17, 0.19, 0.20, 1.0);
uniform vec4 rust_color : source_color = vec4(0.34, 0.16, 0.08, 1.0);

float vhash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(vhash(i), vhash(i + vec2(1.0, 0.0)), f.x),
		mix(vhash(i + vec2(0.0, 1.0)), vhash(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

void fragment() {
	vec2 uvw = UV * 3.0;
	float wear = vnoise(uvw) * 0.7 + vnoise(uvw * 4.0) * 0.3;
	float rust = smoothstep(0.42, 0.78, wear);
	ALBEDO = mix(iron_color.rgb, rust_color.rgb, rust);
	METALLIC = mix(0.75, 0.05, rust);
	ROUGHNESS = mix(0.45, 0.95, rust);
}
