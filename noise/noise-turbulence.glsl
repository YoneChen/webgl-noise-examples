
// Author:
// Title:

#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
float random_value(vec2 st) {
    float h = dot(st,vec2(127.1,311.7));
    return -1. + 2. * fract(sin(h) * 43758.5453123);
}
float noise_value (vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random_value(i);
    float b = random_value(i + vec2(1, 0));
    float c = random_value(i + vec2(0, 1));
    float d = random_value(i + vec2(1, 1));

    // Smooth Interpolation

    // Cubic Hermine Curve.  Same as SmoothStep()
    // vec2 u = f*f*(3.0-2.0*f);
    vec2 u = smoothstep(0.,1.,f);

    // Mix 4 coorners percentages
    return mix(mix(a,b,u.x),mix(c,d,u.x),u.y);
    // return mix(a, b, u.x) +
    //         (c - a)* u.y * (1.0 - u.x) +
    //         (d - b) * u.x * u.y;
}
vec2 random_perlin(vec2 st){
    st = vec2( dot(st,vec2(127.1,311.7)),
              dot(st,vec2(265.4,133.6)) );
    return -1. + 2.0*fract(sin(st)*43758.5453123);
}
float noise_perlin (vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = dot(random_perlin(i),f);
    float b = dot(random_perlin(i + vec2(1., 0.)),f - vec2(1., 0.));
    float c = dot(random_perlin(i + vec2(0., 1.)),f - vec2(0., 1.));
    float d = dot(random_perlin(i + vec2(1., 1.)),f - vec2(1., 1.));

    // Smooth Interpolation

    // Cubic Hermine Curve.  Same as SmoothStep()
    // vec2 u = f*f*(3.0-2.0*f);
    vec2 u = smoothstep(0.,1.,f);

    // Mix 4 coorners percentages
    return mix(mix(a,b,u.x),mix(c,d,u.x),u.y);
}
float noise(vec2 p) {
    return noise_perlin(p);
}
float noise_sum_abs_sin(vec2 p)
{
    float f = 0.0;
    p = p * 4.0;
    float a = 1.;
    for (int i = 0; i < 5; i++) {
        f += a * abs(noise(p));
        p = 2.0 * p;
        a /= 2.;
    }

    return f;
}
float fbm(vec2 p)
{
    float f = 0.0;
    float a = 1.;
    for (int i = 0; i < 5; i++) {
        f += a * noise(p);
        p = 2.0 * p;
        a /= 2.;
    }

    return f;
}
  float pattern( in vec2 p )
  {
      vec2 q = vec2( fbm( p + vec2(0.0,0.0) ),
                     fbm( p + vec2(5.2,1.3) ) );

      vec2 r = vec2( fbm( p + 4.0*q + vec2(1.7,9.2) ),
                     fbm( p + 4.0*q + vec2(8.3,2.8) ) );

      return fbm( p + 4.0*r );
  }

// float fbm ( in vec2 _st) {
//     float v = 0.0;
//     float a = 0.5;
//     vec2 shift = vec2(100.0);
//     // Rotate to reduce axial bias
//     mat2 rot = mat2(cos(0.5), sin(0.5),
//                     -sin(0.5), cos(0.50));
//     for (int i = 0; i < 5; ++i) {
//         v += a * noise(_st);
//         _st = rot * _st * 2.0 + shift;
//         a *= 0.5;
//     }
//     return v;
// }
void main() {
    vec2 st = gl_FragCoord.xy/u_resolution.xy;
    // st.x *= u_resolution.x/u_resolution.y;
	// vec2 pos = vec2(st*15.0);
    float n = pattern(st)*.5+.5; 

    gl_FragColor = vec4(n,n,n,1.0);
}