/*
   Author: rsn8887 (based on TheMaister)
   License: Public domain

   This is an integer prescale filter that should be combined
   with a bilinear hardware filtering (GL_BILINEAR filter or some such) to achieve
   a smooth scaling result with minimum blur. This is good for pixelgraphics
   that are scaled by non-integer factors.
   
   The prescale factor and texel coordinates are precalculated
   in the vertex shader for speed. The precalculation only works on Windows 
   but doesn't work on Raspberry Pi and is therefore disabled for now.
*/

#if defined(VERTEX)

#if __VERSION__ >= 130
#define COMPAT_VARYING out
#define COMPAT_ATTRIBUTE in
#define COMPAT_TEXTURE texture
#else
#define COMPAT_VARYING varying 
#define COMPAT_ATTRIBUTE attribute 
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 COLOR;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 COL0;
COMPAT_VARYING vec4 TEX0;

uniform mat4 MVPMatrix;
uniform int FrameDirection;
uniform int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// vertex compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

/* uncomment for precalculation (not compatible with Raspberry Pi)
out VertexData
{
    vec2 texel;
    vec2 prescale;
} precalcOut;
*/

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy;

/* uncomment for precalculation (not compatible with Raspberry Pi)
    precalcOut.texel = vTexCoord * SourceSize.xy;
    precalcOut.prescale = max(floor(outsize.xy / InputSize.xy), vec2(1.0, 1.0));
*/
}

#elif defined(FRAGMENT)

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

uniform int FrameDirection;
uniform int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define texture(c, d) COMPAT_TEXTURE(c, d)
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

/* uncomment for precalculation (not compatible with Raspberry Pi)
in VertexData
{
    vec2 texel;
    vec2 prescale;
} precalcIn;
*/

void main()
{
/* uncomment for precalculation (not compatible with Raspberry Pi)
   vec2 texel = precalcIn.texel;
   vec2 scale = precalcIn.prescale;
*/
   // comment out next to lines for precalculation (not compatible with RPi)
   vec2 texel = vTexCoord * SourceSize.xy;
   vec2 scale = max(floor(outsize.xy / InputSize.xy), vec2(1.0, 1.0));

   vec2 texel_floored = floor(texel);
   vec2 s = fract(texel);
   vec2 region_range = 0.5 - 0.5 / scale;

   // Figure out where in the texel to sample to get correct pre-scaled bilinear.
   // Uses the hardware bilinear interpolator to avoid having to sample 4 times manually.

   vec2 center_dist = s - 0.5;
   vec2 f = (center_dist - clamp(center_dist, -region_range, region_range)) * scale + 0.5;

   vec2 mod_texel = texel_floored + f;

   FragColor = vec4(texture(Source, mod_texel / SourceSize.xy).rgb, 1.0);
} 
#endif
