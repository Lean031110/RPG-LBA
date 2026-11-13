shader_type spatial;
// Superficie húmeda (charcas, musgo, piedra tras la lluvia): albedo oscurecido,
// roughness que cae en los ángulos rasantes (fresnel) y un filo de brillo suave.
// Sin texturas externas; original y barato para el Compatibility Renderer.
uniform vec4 base_color : source_color = vec4(0.20, 0.15, 0.12, 1.0);
uniform float rough : hint_range(0.1, 1.0) = 0.9;

void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = base_color.rgb * 0.72;
	ROUGHNESS = mix(rough, 0.16, fres);
	SPECULAR = 0.6;
	EMISSION = base_color.rgb * fres * 0.05;
}
