// Author:
// Title:

#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
float random_value(vec3 st) {
    return fract(sin(dot(st,
                         vec3(12.9898,78.233,52.55)))
                 * 43758.5453123);
}
float noise_value (in vec3 st) {
    vec3 i = floor(st);
    vec3 s = fract(st);

    // Four corners in 3D of a tile
    float a = random_value(i);
    float b = random_value(i + vec3(1.0, 0.0, 0.0));
    float c = random_value(i + vec3(0.0, 1.0, 0.0));
    float d = random_value(i + vec3(0.0, 0.0, 1.0));
    float e = random_value(i + vec3(1.0, 1.0, 0.0));
    float f = random_value(i + vec3(1.0, 0.0, 1.0));
    float g = random_value(i + vec3(0.0, 1.0, 1.0));
    float h = random_value(i + vec3(1.0, 1.0, 1.0));

    // Smooth Interpolation

    // Cubic Hermine Curve.  Same as SmoothStep()
    // vec3 u = s*s*(3.0-2.0*s);
    vec3 u = smoothstep(0.,1.,s);

    // Mix 4 coorners percentages
    return mix(mix(mix( a, b, u.x),
                   mix( c, e, u.x), u.y),
               mix(mix( d, f, u.x),
                   mix( g, h, u.x), u.y), u.z);
}
float noise_sum_abs_sin(vec3 p)
{
    float f = 0.0;
    p = p * 20.0;
    f += 1.0000 * abs(noise_value(p)); p = 2.0 * p;
    f += 0.5000 * abs(noise_value(p)); p = 2.0 * p;
    f += 0.2500 * abs(noise_value(p)); p = 2.0 * p;
    f += 0.1250 * abs(noise_value(p)); p = 2.0 * p;
    f += 0.0625 * abs(noise_value(p)); p = 2.0 * p;
    // f = sin(f + p.z/16.0);

    return f;
}
void main() {
    vec2 st = gl_FragCoord.xy/u_resolution.xy;
    // st.x *= u_resolution.x/u_resolution.y;
	// vec2 pos = vec2(st*15.0);
    float n = noise_sum_abs_sin(vec3(st,u_time/50.0)); 
    vec3 color = vec3(n/1.2,n/1.2,n);

    gl_FragColor = vec4(color * 0.8,1.0);
}