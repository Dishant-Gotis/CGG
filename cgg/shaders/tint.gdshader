shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float gray : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float tint_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = texture(screen_texture, SCREEN_UV);
	float luma = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 desat = mix(c.rgb, vec3(luma), gray);
	vec3 tinted = mix(desat, desat * tint_color.rgb, tint_amount);
	COLOR = vec4(tinted, c.a);
}
