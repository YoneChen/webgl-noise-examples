*导语：大自然蕴含着各式各样的纹理，小到细胞菌落分布，大到宇宙星球表面。运用图形噪声，我们可以在3d场景中模拟它们，本文就带大家一起走进万能的图形噪声。*
# 概述
图形噪声，是计算机图形学中一类随机算法，经常用来模拟自然界中的各种纹理材质，如下图的云、山脉等，都是通过噪声算法模拟出来的​。

![Noise构造地形、体积云](https://upload-images.jianshu.io/upload_images/1939855-90915729bb179b00.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
通过不同的噪声算法，作用在物体纹理和材质细节，我们可以模拟不同类型的材质。

![不同Noise生成的材质](https://upload-images.jianshu.io/upload_images/1939855-27216cd7b375fbcd.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

# 基础噪声算法
一个基础的噪声函数的入参通常是一个点坐标（这个点坐标可以是二维的、三维的，甚至N维），返回值是一个浮点数值：`noise(vec2(x,y))`。
我们将这个浮点值转成灰度颜色，形成噪声图，具体可以通过编写片元着色器程序来绘制。

![噪声函数灰度图](https://upload-images.jianshu.io/upload_images/1939855-a2256d9cb35ec9bf.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

上图是各类噪声函数在片元着色器中的运行效果，代码如下：
```glsl
// noise fragment shader
varying vec2 uv;
float noise(vec2 p) {
  // TODO
}
void main() {
    float n = noise(uv);  // 通过噪声函数计算片元坐标对应噪声值
    gl_FragColor = vec4(n, n, n, 1.0);
}
```
其中`noise(st)`的入参`st`是片元坐标，返回的噪声值映射在片元的颜色上。
目前基础噪声算法比较主流的有两类：1. 梯度噪声；2. 细胞噪声；

## 梯度噪声 (Gradient Noise)
梯度噪声产生的纹理具有连续性，所以经常用来模拟山脉、云朵等具有连续性的物质，该类噪声的典型代表是Perlin Noise。

![Perlin Noise为Perlin提出的噪声算法](https://upload-images.jianshu.io/upload_images/1939855-b0a07dfd5f161d8b.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

其它梯度噪声还有Simplex Noise和Wavelet Noise，它们也是由Perlin Noise演变而来。
### 算法步骤
梯度噪声是通过多个随机梯度相互影响计算得到，通过梯度向量的方向与片元的位置计算噪声值。这里以2d举例，主要分为四步：1. 网格生成；2. 网格随机梯度生成；3. 梯度贡献值计算；4. 平滑插值

![Perlin Noise随机向量代表梯度](https://upload-images.jianshu.io/upload_images/1939855-bea8edc3c195461d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

第一步，我们将2d平面分成m×n个大小相同的网格，具体数值取决于我们需要生成的纹理密度（下面以4×4作为例子）；
```glsl
#define SCALE 4. // 将平面分为 4 × 4 个正方形网格
float noise(vec2 p) {
  p *= SCALE;
  // TODO
}
```
第二步，梯度向量生成，这一步是根据第一步生成的网格的顶点来产生随机向量，四个顶点就有四个梯度向量；

![生成随机向量](https://upload-images.jianshu.io/upload_images/1939855-1d6c5af99aebbc3d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

我们需要将每个网格对应的随机向量记录下来，确保不同片元在相同网格中获取的随机向量是一致的。
```glsl
// 输入网格顶点位置，输出随机向量
vec2 random(vec2 p){
	return  -1.0 + 2.0 * fract(
		sin(
			vec2(
				dot(p, vec2(127.1,311.7)),
				dot(p, vec2(269.5,183.3))
			)
		) * 43758.5453
	);
}
```
如上，借用三角函数sin(θ)的来生成随机值，入参是网格顶点的坐标，返回值是随机向量。

第三步，梯度贡献计算，这一步是通过计算四个梯度向量对当前片元点P的影响，主要先求出点P到四个顶点的距离向量，然后和对应的梯度向量进行点积。

![梯度贡献值计算](https://upload-images.jianshu.io/upload_images/1939855-a5bde1d56f59fa84.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

如图，网格内的片元点P的四个顶点距离向量为a1, a2, a3, a4，此时将距离向量与梯度向量g1, g2, g3, g4进行点积运算：c[i] = a[i] · g[i]；

第四步，平滑插值，这一步我们对四个贡献值进行线性叠加，使用`smoothstep()`方法，平滑网格边界，最终得到当前片元的噪声值。具体代码如下：
```glsl
float noise_perlin (vec2 p) {
    vec2 i = floor(p); // 获取当前网格索引i
    vec2 f = fract(p); // 获取当前片元在网格内的相对位置
    // 计算梯度贡献值
    float a = dot(random(i),f); // 梯度向量与距离向量点积运算
    float b = dot(random(i + vec2(1., 0.)),f - vec2(1., 0.));
    float c = dot(random(i + vec2(0., 1.)),f - vec2(0., 1.));
    float d = dot(random(i + vec2(1., 1.)),f - vec2(1., 1.));
    // 平滑插值
    vec2 u = smoothstep(0.,1.,f);
    // 叠加四个梯度贡献值
    return mix(mix(a,b,u.x),mix(c,d,u.x),u.y);
}
```

## 细胞噪声 (Celluar Noise)

![细胞噪声生成水纹](https://upload-images.jianshu.io/upload_images/1939855-1a460033ce0c8562.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

Celluar Noise生成的噪声图由很多个“晶胞”组成，每个晶胞向外扩张，晶胞之间相互抑制。这类噪声可以模拟细胞形态、皮革纹理等。

![worley noise](https://upload-images.jianshu.io/upload_images/1939855-0d60d0c59a19b40f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 算法步骤
细胞噪声算法主要通过距离场的形式实现的，以单个特征点为中心的径向渐变，多个特征点共同作用而成。主要分为三步：1. 网格生成；2. 特征点生成；3. 最近特征点计算

![特征点距离场](https://upload-images.jianshu.io/upload_images/1939855-383ea2dda9f038ec.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

第一步，网格生成：将平面划分为m×n个网格，这一步和梯度噪声的第一步一样；
第二步，特征点生成：为每个网格分配一个特征点`v[i,j]`，这个特征点的位置在网格内随机。
```glsl
// 输入网格索引，输出网格特征点坐标
vec2 random(vec2 st){
	return  fract(
		sin(
			vec2(
				dot(st, vec2(127.1,311.7)),
				dot(st, vec2(269.5,183.3))
			)
		) * 43758.5453
	);
}
```
第三步，针对当前像素点p，计算出距离点p最近的特征点v，将点p到点v的距离记为F1；
```glsl
float noise(vec2 p) {
    vec2 i = floor(p); // 获取当前网格索引i
    vec2 f = fract(p); // 获取当前片元在网格内的相对位置
    float F1 = 1.;
    // 遍历当前像素点相邻的9个网格特征点
    for (int j = -1; j <= 1; j++) {
        for (int k = -1; k <= 1; k++) {
            vec2 neighbor = vec2(float(j), float(k));
            vec2 point = random(i + neighbor);
            float d = length(point + neighbor - f);
            F1 = min(F1,d);
        }
    }
    return F1;
}
```
求解F1，我们可以遍历所有特征点v，计算每个特征点v到点p的距离，再取出最小的距离F1；但实际上，我们只需遍历离点p最近的网格特征点即可。在2d中，则最多遍历包括自身相连的9个网格，如图：

![求解F1：点P的最近特征点距离](https://upload-images.jianshu.io/upload_images/1939855-411adf56c6fd73a7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

最后一步，将F1映射为当前像素点的颜色值，可以是```gl_FragColor = vec4(vec3(pow(noise(uv), 2.)), 1.0);```。
不仅如此，我们还可以取特征点v到点p第二近的距离F2，通过F2 - F1，得到类似泰森多变形的纹理，如上图最右侧。
# 噪声算法组合
前面介绍了两种主流的基础噪声算法，我们可以通过对多个不同频率的同类噪声进行运算，产生更为自然的效果，下图是经过分形操作后的噪声纹理。
![基础噪声 / 分形 / 湍流](https://upload-images.jianshu.io/upload_images/1939855-1e538426c9d41a39.png?imageMogr2x/auto-orient/strip%7CimageView2/2/w/1240)

## 分形布朗运动（Fractal Brownian Motion）
分形布朗运动，简称fbm，是通过将不同频率和振幅的噪声函数进行操作，最常用的方法是：将频率乘2的倍数，振幅除2的倍数，线性相加。

![](https://upload-images.jianshu.io/upload_images/1939855-02389fb8748bbffe.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

- 公式：`fbm = noise(st) + 0.5 * noise(2*st) + 0.25 * noise(4*st)`

```glsl
// fragment shader片元着色器
#define OCTAVE_NUM 5
// 叠加5次的分形噪声
float fbm_noise(vec2 p)
{
    float f = 0.0;
    p = p * 4.0;
    float a = 1.;
    for (int i = 0; i < OCTAVE_NUM; i++)
    {
        f += a * noise(p);
        p = 4.0 * p;
        a /= 4.;
    }
    return f;
}
```

## 湍流（Turbulence）
另外一种变种是在fbm中对噪声函数取绝对值，使噪声值等于0处发生突变，产生湍流纹理：
- 公式：`fbm = |noise(st)| + 0.5 * |noise(2*st)| + 0.25 * |noise(4*st)|`

```glsl
// 湍流分形噪声
float fbm_abs_noise(vec2 p)
{
    ...
    for (int i = 0; i < OCTAVE_NUM; i++)
    {
        f += a * abs(noise(p)); // 对噪声函数取绝对值
        ...
    }
    return f;
}
```
现在结合上文提到的梯度噪声和细胞噪声分别进行fbm，可以实现以下效果：

![Perlin Noise与Worley Noise的2D分形](https://upload-images.jianshu.io/upload_images/1939855-02abc17ebcb582ea.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 翘曲域（Domain Wrapping）

![](https://upload-images.jianshu.io/upload_images/1939855-55c2bf20b958c3b7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

翘曲域噪声用来模拟卷曲、螺旋状的纹理，比如烟雾、大理石等，实现公式如下：

- 公式：`f(p) = fbm( p + fbm( p + fbm( p ) ) )`
```glsl
float domain_wraping( vec2 p )
{
    vec2 q = vec2( fbm(p), fbm(p) );

    vec2 r = vec2( fbm(p + q), fbm(p + q) );

    return fbm( st + r );
}
```
具体实现可参考Inigo Quiles的文章：[https://www.iquilezles.org/www/articles/warp/warp.htm](https://www.iquilezles.org/www/articles/warp/warp.htm)
## 动态纹理
前面讲的都是基于2d平面的静态噪声，我们还可以在2d基础上加上时间t维度，形成动态的噪声。

![2D + Time 动态噪声](https://upload-images.jianshu.io/upload_images/1939855-831e689e7cedd7ee.gif?imageMogr2/auto-orient/strip)

如下为实现3d noise的代码结构：
```glsl
// noise fragment shader
#define SPEED 20.
varying vec2 uv;
uniform float u_time;
float noise(vec3 p) {
  // TODO
}
void main() {
    float n = noise(uv, u_time *  SPEED);  // 传入片元坐标与时间
    gl_FragColor = vec4(n, n, n, 1.0);
}
```
利用时间，我们可以生成实现动态纹理，模拟如火焰、云朵的变换。

![Perlin Noise制作火焰](https://upload-images.jianshu.io/upload_images/1939855-56a58ce3c8e6ab4b.gif?imageMogr2/auto-orient/strip)

## 噪声贴图应用
利用噪声算法，我们可以构造物体表面的纹理颜色和材质细节，在3d开发中，一般采用贴图方式应用在3D Object上的Material材质上。
### Color Mapping
彩色贴图是最常用的是方式，即直接将噪声值映射为片元颜色值，作为材质的Texture图案。

![噪声应用于Color Mapping](https://upload-images.jianshu.io/upload_images/1939855-5d80c980bce83c9a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### Height Mapping
另一种是作为Height Mapping高度贴图，生成地形高度。高度贴图的每个像素映射到平面点的高度值，通过图形噪声生成的Height Map可模拟连绵起伏的山脉。


![Fbm Perlin Noise→heightmap→山脉](https://upload-images.jianshu.io/upload_images/1939855-4acea47bce1270f4.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### Normal Mapping
除了通过heightMap生成地形，还可以通过[法线贴图](https://learnopengl-cn.github.io/05%20Advanced%20Lighting/04%20Normal%20Mapping/)改变光照效果，实现材质表面的凹凸细节。

![Worley Noise→Normalmap→地表细节](https://upload-images.jianshu.io/upload_images/1939855-460384e5b267f6e9.png?imageMogr2/auto-orient/stripxie%7CimageView2/2/w/1240)

这里的噪声值被映射为法线贴图的color值。

## 噪声贴图实践
在WebGL中使用噪声贴图通常有两种方法：
1. 读取一张静态noise图片的噪声值；
1. 加载noise程序，切换着色器中运行它
前者不必多说，适用于静态纹理材质，后者适用于动态纹理，这里主要介绍后者的实现。

![](https://upload-images.jianshu.io/upload_images/1939855-064bd245ace18fe3.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

这里将通过实现如上图球体的纹理贴图效果，为了简化代码，我使用Three.js来实现：
首先，按往常一样创建场景、相机、渲染器，在初始化阶段创建一个球体，我们将把噪声纹理应用在这颗球体上：
```JavaScript
class Web3d {
    constructor() { ... } // 创建场景、相机、渲染器
    // 渲染前初始化钩子
    start() {
        this.addLight(); // 添加灯光
        this.addBall(); // 添加一个球体
    }
    addBall() {
        const { scene } = this;
        this.initNoise();
        const geometry = new THREE.SphereBufferGeometry(50, 32, 32); // 创建一个半径为50的球体
        // 创建材质
        const material = new THREE.MeshPhongMaterial( {
            shininess: 5,
            map: this.colorMap.texture // 将噪声纹理作为球体材质的colorMap
        } );
        const ball = new THREE.Mesh( geometry, material );
        ball.rotation.set(0,-Math.PI,0);
        scene.add(ball);
    }
    // 动态渲染更新钩子
    update() { }
}
```
接着，编写Noise shader程序，我们把前面的梯度噪声shader搬过来稍微封装下：
```javascript
const ColorMapShader = {
    uniforms: {
        "scale": { value: new THREE.Vector2( 1, 1 ) },
        "offset": { value: new THREE.Vector2( 0, 0 ) },
        "time": { value: 1.0 },
    },
    vertexShader: `
        varying vec2 vUv;
        uniform vec2 scale;
        uniform vec2 offset;

        void main( void ) {
            vUv = uv * scale + offset;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    `,
    fragmentShader: `
        varying vec2 vUv;
        uniform float time;
        vec3 random_perlin( vec3 p ) {
            p = vec3(
                    dot(p,vec3(127.1,311.7,69.5)),
                    dot(p,vec3(269.5,183.3,132.7)), 
                    dot(p,vec3(247.3,108.5,96.5)) 
                    );
            return -1.0 + 2.0*fract(sin(p)*43758.5453123);
        }
        float noise_perlin (vec3 p) {
            vec3 i = floor(p);
            vec3 s = fract(p);

            // 3D网格有8个顶点
            float a = dot(random_perlin(i),s);
            float b = dot(random_perlin(i + vec3(1, 0, 0)),s - vec3(1, 0, 0));
            float c = dot(random_perlin(i + vec3(0, 1, 0)),s - vec3(0, 1, 0));
            float d = dot(random_perlin(i + vec3(0, 0, 1)),s - vec3(0, 0, 1));
            float e = dot(random_perlin(i + vec3(1, 1, 0)),s - vec3(1, 1, 0));
            float f = dot(random_perlin(i + vec3(1, 0, 1)),s - vec3(1, 0, 1));
            float g = dot(random_perlin(i + vec3(0, 1, 1)),s - vec3(0, 1, 1));
            float h = dot(random_perlin(i + vec3(1, 1, 1)),s - vec3(1, 1, 1));

            // Smooth Interpolation
            vec3 u = smoothstep(0.,1.,s);

            // 根据八个顶点进行插值
            return mix(mix(mix( a, b, u.x),
                        mix( c, e, u.x), u.y),
                    mix(mix( d, f, u.x),
                        mix( g, h, u.x), u.y), u.z);
        }
        float noise_turbulence(vec3 p)
        {
            float f = 0.0;
            float a = 1.;
            p = 4.0 * p;
            for (int i = 0; i < 5; i++) {
                f += a * abs(noise_perlin(p));
                p = 2.0 * p;
                a /= 2.;
            }
            return f;
        }
        void main( void ) {
            float c1 = noise_turbulence(vec3(vUv, time/10.0));
            vec3 color = vec3(1.5*c1, 1.5*c1*c1*c1, c1*c1*c1*c1*c1*c1);
            gl_FragColor = vec4( color, 1.0 );
        }
    `
};
```
OK，现在让WebGL去加载这段程序，并告诉它这段代码是要作为球体的纹理贴图的：
```
    initNoise() {
        const { scene, renderer } = this;
        // 创建一个噪声平面，作为运行噪声shader的载体。
        const plane = new THREE.PlaneBufferGeometry( window.innerWidth, window.innerHeight );
        const colorMapMaterial = new THREE.ShaderMaterial( {
            ...ColorMapShader, // 将噪声着色器代码传入ShaderMaterial
            uniforms: {
                ...ColorMapShader.uniforms,
                scale: { value: new THREE.Vector2( 1, 1 ) }
            },
            lights: false
        } );
        const noise = new THREE.Mesh( plane, colorMapMaterial );
        scene.add( noise );
        // 创建噪声纹理的渲染对象framebuffer。
        const colorMap = new THREE.WebGLRenderTarget( 512, 512 );
        colorMap.texture.generateMipmaps = false;
        colorMap.texture.wrapS = colorMap.texture.wrapT = THREE.RepeatWrapping;
        this.noise = noise;
        this.colorMap = colorMap;
        this.uniformsNoise = colorMapMaterial.uniforms;
        // 创建一个正交相机，对准噪声平面。
        this.cameraOrtho = new THREE.OrthographicCamera( window.innerWidth / - 2, window.innerWidth / 2, window.innerHeight / 2, window.innerHeight / - 2, - 10000, 10000 );
        this._renderNoise();
    }
```
第四步，让renderer动态运行噪声shader，更新噪声变量，可以是时间、颜色、偏移量等。
```javascript
    _renderNoise() {
        const { scene, noise, colorMap, renderer, cameraOrtho } = this;
        noise.visible = true;
        renderer.setRenderTarget( colorMap );
        renderer.clear();
        renderer.render( scene, cameraOrtho );
        noise.visible = false;
    }
    update(delta) {
        this.uniformsNoise[ 'time' ].value += delta; // 更新noise的时间，生成动态纹理
        this._renderNoise();
    }
```
通过同样的方法，我们可以试着用在将高度贴图上，比如用Worley Noise构造的鹅卵石地表。

![Worley Noise构造地形](https://upload-images.jianshu.io/upload_images/1939855-b49e2fd416d4ae30.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

# 参考资料
- OpenGL复杂地形的Shader实现：[https://blog.csdn.net/Mahabharata_/article/details/78168432](https://blog.csdn.net/Mahabharata_/article/details/78168432)
- The Book of Shader - 图形噪声：[https://thebookofshaders.com/11/](https://thebookofshaders.com/11/)
