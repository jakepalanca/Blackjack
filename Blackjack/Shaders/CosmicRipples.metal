#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h> // Provides types like metal::float2

using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// Simple noise function (you can replace with something more sophisticated)
float random(float2 p) {
    return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}

// Vertex shader: passes through normalized coordinates
[[vertex]]
VertexOut vertex_main(uint vid [[vertex_id]], constant float2 *screen_size [[buffer(0)]]) {
    VertexOut out;
    // Simplified: just create a full-screen quad.
    // More robust would be to pass actual vertex data for a quad.
    float2 positions[4] = {
        float2(-1.0, -1.0), float2(1.0, -1.0),
        float2(-1.0,  1.0), float2(1.0,  1.0)
    };
    float2 texCoords[4] = {
        float2(0.0, 1.0), float2(1.0, 1.0),
        float2(0.0, 0.0), float2(1.0, 0.0)
    };

    // For a triangle strip
    if (vid == 0) { out.position = float4(positions[0], 0.0, 1.0); out.texCoord = texCoords[0];}
    else if (vid == 1) { out.position = float4(positions[1], 0.0, 1.0); out.texCoord = texCoords[1];}
    else if (vid == 2) { out.position = float4(positions[2], 0.0, 1.0); out.texCoord = texCoords[2];}
    else { // vid == 3
        // This forms the second triangle for the quad using a triangle strip.
        // To make it a quad, we'd typically use two triangles (6 vertices) or an index buffer.
        // For simplicity with a single draw call of 4 vertices using triangle_strip:
        out.position = float4(positions[3], 0.0, 1.0); out.texCoord = texCoords[3];
    }
    // If your MTKView is set up for triangle strip, you'd draw 4 vertices.
    // The above is a bit of a hack for triangle strips. A common setup uses 2 triangles (6 vertices).
    // Let's assume a setup that draws 4 vertices as a triangle strip for a full-screen quad.

    return out;
}


// Fragment shader: renders starfield with ripple
[[fragment]]
float4 fragment_main(VertexOut in [[stage_in]],
                     constant float *time [[buffer(0)]],
                     constant float2 *touchPoint [[buffer(1)]], // Expects normalized coordinates (0-1)
                     constant float2 *resolution [[buffer(2)]])
{
    float2 uv = in.texCoord; // Already normalized (0-1)

    // Ripple effect
    float2 distCoord = uv - *touchPoint;
    float dist = length(distCoord);
    float ripple = sin(dist * 25.0 - *time * 5.0) * 0.03; // Amplitude and speed of ripple
    ripple *= smoothstep(0.6, 0.0, dist); // Fade ripple further away
    
    float2 distortedUv = uv + distCoord * ripple;

    // Starfield
    float starIntensity = 0.0;
    float2 starUv = distortedUv * 5.0; // Scale for more stars
    float starRandom = random(floor(starUv));
    
    if (starRandom > 0.985) { // Adjust threshold for star density
        float starSize = (random(floor(starUv) + 0.1) * 0.05) + 0.002; // Vary star sizes
        float starDist = length(fract(starUv) - 0.5);
        starIntensity = smoothstep(starSize, 0.0, starDist);
    }

    // Base dark space color
    float4 color = float4(0.01, 0.02, 0.05, 1.0); // Dark blue/purple

    // Add stars
    color.rgb += float3(starIntensity);

    return color;
}
