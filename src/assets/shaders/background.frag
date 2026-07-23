extern float time;

float hash(vec2 p)
{
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 pc)
{
    vec2 uv = pc / love_ScreenSize.xy;

    const float GRID = 160.0;

    vec2 grid = uv * GRID;
    vec2 cell = floor(grid);
    vec2 f = fract(grid);

    float h = hash(cell);

    if (h < 0.92)
        return vec4(0.0, 0.0, 0.0, 1.0);

    vec2 starPos = vec2(
        hash(cell + 17.3),
        hash(cell + 91.7)
    );

    float d = length(f - starPos);

    float size = mix(0.015, 0.135, pow(hash(cell + 43.2), 2.0));
    float star = smoothstep(size, size * 0.25, d);
    star += smoothstep(size * 2.5, 0.0, d) * 0.25;
    float brightness = mix(0.3, 1.0, hash(cell + 71.8));
    float speed = mix(0.5, 3.0, hash(cell + 128.0));
    float phase = hash(cell + 8.7) * 6.28318;

    float twinkle = 0.75 + 0.25 * sin(time * speed + phase);

    star *= brightness * twinkle;

    return vec4(vec3(star), 1.0);
}

