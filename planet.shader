shader_type spatial;

render_mode cull_back;

uniform sampler2D texture1; 

uniform sampler2D texture2; 

uniform sampler2D texture3; 

uniform sampler2D texture4; 

uniform sampler2D grid_texture;

uniform sampler2D map_texture;

uniform bool enable_grid = false;

uniform float sphere_ratio = 0.01;

uniform float hdecr_factor = 0.0;

uniform vec2 tpos;

uniform vec2 rpos;

varying vec4 mtVal;

float wrap(float v)
{
	return mod(v, 128.0);
}

int wrapi(int v)
{
	return v % 128;
}

void vertex()
{	
	int x = wrapi(int(VERTEX.x) - int(rpos.x));
	int z = wrapi(int(VERTEX.z) - int(rpos.y));
	float hL = texelFetch(map_texture, ivec2(wrapi(x-1), z), 0).r;
	float hR = texelFetch(map_texture, ivec2(wrapi(x+1), z), 0).r;
	float hD = texelFetch(map_texture, ivec2(x, wrapi(z-1)), 0).r;
	float hU = texelFetch(map_texture, ivec2(x, wrapi(z+1)), 0).r;
	vec3 n;
	n.x = hL - hR;
	n.y = hD - hU;
	n.z = 2.0;
	n = normalize(n);
	NORMAL = n;
	
	float c2 = texelFetch(map_texture, ivec2(x, z), 0).r;
	
	VERTEX.x += tpos.x;
	VERTEX.z += tpos.y;
	
	VERTEX.y = c2 * 2.0;

	if(VERTEX.y == 0.0)
		COLOR = vec4(0.0,0.0,1.0,1.0);
	else
		COLOR = vec4(1.0,1.0,1.0,1.0);
	float f1 = VERTEX.x;
	float f2 = VERTEX.z;
	f1 = f1 * f1;
	f2 = f2 * f2;
	float rf1 = sqrt(f1 + f2);
	float h = VERTEX.y * 8.0;
	mtVal.x = clamp(1.0 - abs((h - 0.0) / 5.0), 0.0, 1.0);
	mtVal.y = clamp(1.0 - abs((h - 5.0) / 5.0), 0.0, 1.0);
	mtVal.z = clamp(1.0 - abs((h - 10.0) / 5.0), 0.0, 1.0);
	mtVal.w = clamp(1.0 - abs((h - 20.0) / 10.0), 0.0, 1.0);
	float total = mtVal.x + mtVal.y + mtVal.z + mtVal.w;
	mtVal.x /= total;
	mtVal.y /= total;
	mtVal.z /= total;
	mtVal.w /= total;
	VERTEX.y = clamp(VERTEX.y - hdecr_factor, 0, 1000);
	VERTEX.y += -rf1*rf1*sphere_ratio;
}

void fragment()
{	
	vec2 uv = UV.xy;
	
	ALBEDO = texture(texture1, uv).rgb * mtVal.x;
	ALBEDO += texture(texture2, uv).rgb * mtVal.y;
	ALBEDO += texture(texture3, uv).rgb * mtVal.z;
	ALBEDO += texture(texture4, uv).rgb * mtVal.w;
	
	if(enable_grid)
	{
		vec4 t = texture(grid_texture, uv).rgba;
		if(t.a==0.0)
		{
			ALBEDO.rgb *= COLOR.rgb;	
		}
		else
		{
			ALBEDO.rgb *= t.rgb * COLOR.rgb;
		}
	}
	else
	{	
			ALBEDO.rgb *= COLOR.rgb;	
	}
}