precision mediump float;

attribute vec3 position;
attribute vec2 texcoord;
attribute vec3 normal;

varying vec3 object_position;
varying vec3 object_normal;
varying vec2 object_texcoord;

uniform mat4 View;
uniform mat4 Proj;
uniform mat4 World;

void main()
{
    gl_Position = Proj * View * World * vec4(position, 1.0);
    object_position = vec3(World * vec4(position, 1.0));
    object_normal = vec3(World * vec4(normal, 1.0));
    object_texcoord = texcoord;
}
