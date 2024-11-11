const gl = @cImport(@cInclude("glad.h"));
const glm = @cImport({
    @cInclude("cglm/cglm.h");
});

pub const MKShader = struct {
    shaderProgram: u32,

    pub fn init() !MKShader {
        const vertexShaderSource = &[_][*c]const u8{
            \\#version 330 core
            \\layout (location = 0) in vec3 aPos;
            \\layout (location = 1) in vec2 aUV;
            \\out vec2 TexCoord;
            \\uniform mat4 transform;
            \\uniform mat4 projection;
            \\uniform mat4 view;
            \\void main() {
            \\    gl_Position = projection * view * transform * vec4(aPos, 1.0);
            \\    TexCoord = aUV;
            \\}
        };

        const fragmentShaderSource = &[_][*c]const u8{
            \\#version 330 core
            \\in vec2 TexCoord;
            \\out vec4 FragColor;
            \\uniform sampler2D aTexture;
            \\uniform vec4 aColor;
            \\uniform bool useTexture;
            \\void main() {
            \\    vec4 textureColor = texture(aTexture, TexCoord);
            \\    if (useTexture && textureColor.a < 0.1) discard;
            \\    FragColor = useTexture ? textureColor * (aColor / 255) : aColor / 255;
            \\}
        };

        // Compile and attach vertex shader
        const vertexShader: u32 = gl.glCreateShader(gl.GL_VERTEX_SHADER);
        gl.glShaderSource(vertexShader, 1, vertexShaderSource, null);
        gl.glCompileShader(vertexShader);

        // Compile and attach fragment shader
        const fragmentShader: u32 = gl.glCreateShader(gl.GL_FRAGMENT_SHADER);
        gl.glShaderSource(fragmentShader, 1, fragmentShaderSource, null);
        gl.glCompileShader(fragmentShader);

        // Shader program
        const shaderProgram: u32 = gl.glCreateProgram();
        gl.glAttachShader(shaderProgram, vertexShader);
        gl.glAttachShader(shaderProgram, fragmentShader);
        gl.glLinkProgram(shaderProgram);

        // Delete shaders after linking
        gl.glDeleteShader(vertexShader);
        gl.glDeleteShader(fragmentShader);

        return MKShader{
            .shaderProgram = shaderProgram,
        };
    }

    pub fn deinit(self: *MKShader) void {
        gl.glDeleteProgram(self.shaderProgram);
    }

    pub fn setUniformM4(self: *MKShader, key: [*c]const u8, value: [4][4]f32) void {
        gl.glUniformMatrix4fv(gl.glGetUniformLocation(self.shaderProgram, key), 1, gl.GL_FALSE, &value[0][0]);
    }

    pub fn setUniformVM4(self: *MKShader, key: [*c]const u8, value: glm.vec4) void {
        gl.glUniformMatrix4fv(gl.glGetUniformLocation(self.shaderProgram, key), 1, gl.GL_FALSE, &value);
    }

    pub fn setUniformInt(self: *MKShader, key: [*c]const u8, value: i32) void {
        gl.glUniform1i(gl.glGetUniformLocation(self.shaderProgram, key), value);
    }
};
