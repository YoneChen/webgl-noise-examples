// Author: @patriciogv
// Title: CellularNoise

#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}
float get_min_dist(vec2 st) {
    // Tile the space
    vec2 i_st = floor(st);
    vec2 f_st = fract(st);
    float min_dist = 1.;
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vec2 neighbor = vec2(float(i),float(j));
            vec2 point = random2(i_st + neighbor);
            point = .5 + .5 * sin(u_time + 6.2831*point);
            float d = length(point + neighbor - f_st);
            min_dist = min(min_dist,d);
        }
    }
    return min_dist;
}
void main() {
    vec2 st = gl_FragCoord.xy/u_resolution.xy;
    st.x *= u_resolution.x/u_resolution.y;
    vec3 color = vec3(.0);

    // Scale
    st *= 10.;


    // vec2 point = .5 * random2(i_st) + .5 * sin(u_time + 16.234 * i_st );
    // vec2 point = random2(i_st);
    // vec2 diff = point - f_st;

    // float dist = length(diff);
    float dist = get_min_dist(st);
    // Draw the min distance (distance field)
    color += dist;

    // Show isolines
    // color -= step(.7,abs(sin(27.0*dist)))*.5;

    gl_FragColor = vec4(color,1.0);
}
