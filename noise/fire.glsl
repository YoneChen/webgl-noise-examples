//////////////////////
// Fire Flame shader
#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
vec2 hash( vec2 p )
{
	p = vec2( dot(p,vec2(127.1,311.7)),
			 dot(p,vec2(269.5,183.3)) );
	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise(vec2 p)
{
    const float K1=0.366025404;//(sqrt(3)-1)/2)
    const float K2=0.211324865;//(3-sqrt(3))/6;
    
    vec2 i=floor(p+(p.x+p.y)*K1);
    
    vec2 a=p-(i-(i.x+i.y)*K2);
    vec2 o=(a.x<a.y)?vec2(0.0,1.0):vec2(1.0,0.0);
    vec2 b=a-o+K2;
    vec2 c=a-1.0+2.0*K2;
    
    vec3 h = max( 0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
	
	vec3 n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
	
	return dot( n, vec3(70.0) );
    
}

float fbm(vec2 uv)
{
    float f=0.0;
    uv=uv*2.0;
	f  = 0.5000*noise( uv ); uv = 2.0*uv;
	f += 0.2500*noise( uv ); uv = 2.0*uv;
	f += 0.1250*noise( uv ); uv = 2.0*uv;
	f += 0.0625*noise( uv ); uv = 2.0*uv;
	f = f+0.5;
	return f;
}
// no defines, standard redish flames
//#define BLUE_FLAME
//#define GREEN_FLAME

void main()
{
    vec2 uv = gl_FragCoord.xy/u_resolution.xy;
	vec2 q = uv;
    q.x*=5.;
	float strength =1.5;
	float T = 1.5*u_time;
	q.x-=2.5;//Ox=2.5
	q.y-=0.25;//Oy=0.25
    
    //the first layer of noise
	float n = fbm(strength*q - vec2(0,T));
    float gradient = n*q.y;
    //the second layer of noise
    float mask = length(q);
    float c=1.-16.*(pow(mask-gradient,2.));
    
    //using the noise to generate pixel color;
    float c1=n*c*(1.-pow(uv.y,4.));
	c1=clamp(c1,0.,1.);

    //color
	vec3 col = vec3(1.5*c1, 1.5*c1*c1*c1, c1*c1*c1*c1*c1*c1);
    
    //the mix paramter，c1/n
	float c2 = c * (1.-pow(uv.y,4.));
	gl_FragColor = vec4( mix(vec3(0.),col,c2), 1.0);
}