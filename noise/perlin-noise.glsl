// Author: yonechen
// Title: nosie with time

#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
float random_value(vec3 st) {
    float h = dot(st,vec3(127.1,311.7,69.5));
    return -1. + 2. * fract(sin(h) * 43758.5453123);
}
float noise_value (in vec3 st) {
    vec3 i = floor(st);
    vec3 s = fract(st);

    // Four corners in 3D of a tile
    float a = random_value(i);
    float b = random_value(i + vec3(1, 0, 0));
    float c = random_value(i + vec3(0, 1, 0));
    float d = random_value(i + vec3(0, 0, 1));
    float e = random_value(i + vec3(1, 1, 0));
    float f = random_value(i + vec3(1, 0, 1));
    float g = random_value(i + vec3(0, 1, 1));
    float h = random_value(i + vec3(1, 1, 1));

    // Smooth Interpolation

    // Cubic Hermine Curve.  Same as SmoothStep()
    // vec3 u = s*s*(3.0-2.0*s);
    vec3 u = smoothstep(0.,1.,s);

    // Mix 8 coorners percentages
    return mix(mix(mix( a, b, u.x),
                   mix( c, e, u.x), u.y),
               mix(mix( d, f, u.x),
                   mix( g, h, u.x), u.y), u.z);
}
vec3 random_perlin(vec3 st){
    st = vec3(
            dot(st,vec3(127.1,311.7,69.5)),
            dot(st,vec3(269.5,183.3,132.7)), 
            dot(st,vec3(247.3,108.5,96.5)) 
            );
    return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}
float noise_perlin (vec3 st) {
    vec3 i = floor(st);
    vec3 s = fract(st);

    // Four corners in 3D of a tile
    float a = dot(random_perlin(i),s);
    float b = dot(random_perlin(i + vec3(1, 0, 0)),s - vec3(1, 0, 0));
    float c = dot(random_perlin(i + vec3(0, 1, 0)),s - vec3(0, 1, 0));
    float d = dot(random_perlin(i + vec3(0, 0, 1)),s - vec3(0, 0, 1));
    float e = dot(random_perlin(i + vec3(1, 1, 0)),s - vec3(1, 1, 0));
    float f = dot(random_perlin(i + vec3(1, 0, 1)),s - vec3(1, 0, 1));
    float g = dot(random_perlin(i + vec3(0, 1, 1)),s - vec3(0, 1, 1));
    float h = dot(random_perlin(i + vec3(1, 1, 1)),s - vec3(1, 1, 1));

    // Smooth Interpolation

    // Cubic Hermine Curve.  Same as SmoothStep()
    // vec2 u = f*f*(3.0-2.0*f);
    vec3 u = smoothstep(0.,1.,s);

    // Mix 8 coorners percentages
    return mix(mix(mix( a, b, u.x),
                   mix( c, e, u.x), u.y),
               mix(mix( d, f, u.x),
                   mix( g, h, u.x), u.y), u.z);
}
float noise(vec3 p) {
    return noise_perlin(p);
}
float noise_fbm(vec3 p)
{
    float f = 0.0;
    p = p * 4.0;
    float a = 2.;
    for (int i = 0; i < 6; i++) {
        f += a * noise(p);
        p = 2.0 * p;
        a /= 2.;
    }
    // f = sin(f + p.x/1000.0);

    return f * .5 + .5;
}
float noise_fbm_abs(vec3 p)
{
    float f = 0.0;
    p = p * 4.0;
    float a = 1.;
    for (int i = 0; i < 6; i++) {
        f += a * abs(noise(p));
        p = 2.0 * p;
        a *= .5;
    }

    // f = sin(f + p.x/16.0);

    return f;
}
void main() {
    vec2 st = gl_FragCoord.xy/u_resolution.xy;
    // st.x *= u_resolution.x/u_resolution.y;
	// vec2 pos = vec2(st*15.0);
    float n = 0.;
    vec3 color = vec3(0.);
    if (st.x < .5 && st.y > .5) {
        n = noise(vec3(st,u_time/10.0)*16.)* .5 + .5; 
        color = vec3(n);
    } else if (st.x < .5 && st.y < .5) {
        n = noise_fbm_abs(vec3(st,u_time/10.0));
        color = vec3(n);
    } else if (st.x > .5 && st.y > .5) {
        n = noise_fbm(vec3(st,u_time/10.0)); 
        color = vec3(n);
    } else if (st.x >.5 && st.y < .5) {
        n = noise_fbm_abs(vec3(st,u_time/10.0)); 
        color = vec3(1.-n);
    }

    gl_FragColor = vec4(color,1.0);
}