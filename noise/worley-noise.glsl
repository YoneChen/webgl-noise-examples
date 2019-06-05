// Author: @yonechen
// Title: CellularNoise

#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

vec3 random( vec3 p ) {
    return fract(
        sin(
            vec3(
                dot(p,vec3(127.1,311.7,82.3)),
                dot(p,vec3(269.5,183.3,201.7)),
                dot(p,vec3(169.2,88.3,123.7))
            )
        )*43758.5453
    );
}
float get_F1(vec3 st) {
    // Tile the space
    vec3 i_st = floor(st);
    vec3 f_st = fract(st);
    float min_dist = 1.;
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            for (int k = -1; k <= 1; k++) {
                vec3 neighbor = vec3(float(i),float(j),float(k));
                vec3 point = random(i_st + neighbor);
                float d = length(point + neighbor - f_st);
                min_dist = min(min_dist,d);
            }
        }
    }
    return pow(min_dist,2.);
}
float get_F2_F1(vec3 st) {
    // Tile the space
    float dists[27];
    vec3 i_st = floor(st);
    vec3 f_st = fract(st);
    float min_dist = 10.;
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            for (int k = -1; k <= 1; k++) {
                vec3 neighbor = vec3(float(i),float(j),float(k));
                vec3 point = random(i_st + neighbor);
                float d = length(point + neighbor - f_st);
                dists[(i + 1) * 9 + (j + 1) * 3 + (k + 1)] = d;
                min_dist = min(min_dist,d);
            }
        }
    }
    float sec_min_dist = 10.;
    for (int i = 0; i < 27; i++) {
        if (dists[i] != min_dist) {
            sec_min_dist = min(sec_min_dist,dists[i]);
        }
    }
    
    return pow(sec_min_dist - min_dist,.5);
}
float noise_fbm_F1(vec3 p)
{
    float f = 0.0;
    float a = 0.7;
    for (int i = 0; i < 4; i++) {
        f += a * get_F1(p);
        p = 2. * p;
        a /= 2.;
    }

    return f;
}
float noise_fbm_F2_F1(vec3 p)
{
    float f = 0.0;
    float a = 0.7;
    for (int i = 0; i < 4; i++) {
        f += a * get_F2_F1(p);
        p = 2. * p;
        a /= 2.;
    }

    return f;
}
float noise_fbm_abs_F2_F1(vec3 p)
{
    float f = 0.0;
    float a = 0.7;
    for (int i = 0; i < 4; i++) {
        f += a * abs(get_F2_F1(p)-.5);
        p = 2. * p;
        a /= 2.;
    }

    return f;
}
float noise_fbm_abs_F1(vec3 p)
{
    float f = 0.0;
    float a = 0.7;
    for (int i = 0; i < 4; i++) {
        f += a * abs(get_F1(p)-.5);
        p = 2. * p;
        a /= 2.;
    }

    return f;
}
#define SCALE 20.
void main() {
    vec2 uv = gl_FragCoord.xy/u_resolution.xy;
    // st.x *= u_resolution.x/u_resolution.y;
    vec3 color = vec3(0.0);

    // Scale
    uv *= SCALE;
    // float dist = length(diff);
    float dist = 0.;
    // Draw the min distance (distance field)
    vec3 st = vec3(uv,u_time);
    if (uv.x < SCALE/2. && uv.y > SCALE/3.*2.) {
        dist = get_F1(st);
        color += dist;
    } else if (uv.x > SCALE/2. && uv.y > SCALE/3.*2.){
        color = vec3(1.0);
        dist = get_F1(st);
        color -= dist;
    } else if (uv.x < SCALE/2. && uv.y < SCALE/3.){
        // color = vec3(1.0);
        dist = noise_fbm_F1(st);
        color += dist;
    } else if (uv.x < SCALE/2. && uv.y > SCALE/3. && uv.y < SCALE/3.*2.){
        dist = get_F2_F1(st);
        color += dist;
    } else if (uv.x > SCALE/2. && uv.y > SCALE/3. && uv.y < SCALE/3.*2.){
        color = vec3(1.0);
        dist = get_F2_F1(st);
        color -= dist;
    } else if (uv.x > SCALE/2. && uv.y < SCALE/3.){
        dist = noise_fbm_abs_F1(st);
        color += dist;
    }

    // Show isolines
    // color -= step(.7,abs(sin(27.0*dist)))*.5;

    gl_FragColor = vec4(color,1.0);
}
