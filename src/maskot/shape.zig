const std = @import("std");
const gl = @cImport(@cInclude("glad.h"));
const stb = @cImport(@cInclude("stb_image.h"));
const maskot = @import("maskot.zig");
const utils = @import("maskot.zig").texture;
const glm = @cImport({
    @cInclude("cglm/call.h");
});

var VAO: gl.GLuint = 0;
var VBO: gl.GLuint = 0;
var EBO: gl.GLuint = 0;

pub const Vertex = struct {
    position: [3]f32,
    uv: ?[2]f32 = null,

    pub fn setAttributes(vertex: *const Vertex) void {
        var offset: usize = 0;

        // Position
        // -------------
        gl.glVertexAttribPointer(0, 3, gl.GL_FLOAT, gl.GL_FALSE, @sizeOf(Vertex), @ptrFromInt(offset));
        gl.glEnableVertexAttribArray(0);
        offset += @sizeOf([3]f32);

        // UV
        // -------------
        if (vertex.uv != null) {
            gl.glVertexAttribPointer(1, 2, gl.GL_FLOAT, gl.GL_FALSE, @sizeOf(Vertex), @ptrFromInt(offset));
            gl.glEnableVertexAttribArray(1);
            offset += @sizeOf([2]f32);
        }
    }
};

pub fn mat4_mul(a: [4][4]f32, b: [4][4]f32) [4][4]f32 {
    var result: [4][4]f32 = undefined;
    for (0..4) |i| {
        for (0..4) |j| {
            result[i][j] = a[i][0] * b[0][j] + a[i][1] * b[1][j] + a[i][2] * b[2][j] + a[i][3] * b[3][j];
        }
    }
    return result;
}

// ------------------------------
// FIX: Why enum?
pub const Camera = enum {
    Orthographic,
    Perspective,

    pub var fov: f32 = 100;
    pub var near: f32 = 0.01;
    pub var far: f32 = 1500;
    pub var aspect: f32 = 0 / 0;

    pub var yaw: f32 = 0;
    pub var pitch: f32 = 0;

    pub var position: [3]f32 = [3]f32{ 0, 0, 0 };
    pub var direction: [3]f32 = [3]f32{ 0, 0, 1 };
};

// ------------------------------
pub const DrawMode = enum {
    FILL,
    LINE,
};

// ------------------------------
pub const DrawSettings = struct {
    color: [4]u8 = [4]u8{ 255, 255, 255, 255 },
    texture: ?*utils.Texture = null,
    shader: *maskot.shader.MKShader = &maskot.window.shader,
    drawMode: DrawMode = DrawMode.FILL,
    camera: Camera = Camera.Orthographic,
    zIndex: i32 = 0,
};

pub const ShapeBuilder = struct {
    vertices: []const Vertex,
    indices: []const u32,

    pub fn init(vertices: []const Vertex, indices: []const u32) ShapeBuilder {
        // Vertex Array Object (VAO)
        gl.glGenVertexArrays(1, &VAO);
        gl.glBindVertexArray(VAO);

        // Vertex Buffer Object (VBO)
        gl.glGenBuffers(1, &VBO);
        gl.glBindBuffer(gl.GL_ARRAY_BUFFER, VBO);

        // Set buffer data
        const vertices_ptr: *const anyopaque = @ptrCast(vertices.ptr);
        const size: c_long = @intCast(@sizeOf(Vertex) * vertices.len);
        gl.glBufferData(gl.GL_ARRAY_BUFFER, size, vertices_ptr, gl.GL_STATIC_DRAW);

        // Set up vertex attribute pointers
        Vertex.setAttributes(&vertices[0]);

        // Create Element Buffer Object (EBO) for indices if they are provided
        if (indices.len > 0) {
            gl.glGenBuffers(1, &EBO);
            gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, EBO);

            const indices_ptr: *const anyopaque = @ptrCast(indices.ptr);
            const indices_size: c_long = @intCast(@sizeOf(u32) * indices.len);
            gl.glBufferData(gl.GL_ELEMENT_ARRAY_BUFFER, indices_size, indices_ptr, gl.GL_STATIC_DRAW);
        }

        // Unbind VBO and VAO
        gl.glBindBuffer(gl.GL_ARRAY_BUFFER, 0);
        gl.glBindVertexArray(0);

        return ShapeBuilder{
            .vertices = vertices,
            .indices = indices,
        };
    }

    pub fn deinit(self: *ShapeBuilder) void {
        _ = self;

        gl.glDeleteVertexArrays(1, &VAO);
        gl.glDeleteBuffers(1, &VBO);
        gl.glDeleteBuffers(1, &EBO);
    }

    // TODO: apply uniform only on-change

    var prevColor: [4]u8 = undefined;
    var prevTexture: *maskot.texture.Texture = undefined;

    // ------------------------------
    pub fn draw(self: *ShapeBuilder, x: f32, y: f32, w: f32, h: f32, settings: DrawSettings) void {
        var projection: [4][4]f32 = undefined;
        var view: [4][4]f32 = undefined;

        var translation: [4][4]f32 = undefined;
        var scaling: [4][4]f32 = undefined;
        var transform: [4][4]f32 = undefined;

        // --------------
        // Create translation matrix
        var translate_vec: [3]f32 = [3]f32{ x, y, @as(f32, @floatFromInt(settings.zIndex)) / 1000 };
        glm.glm_translate_make(&translation, &translate_vec[0]);

        // Create scaling matrix
        var scale_vec: [3]f32 = [3]f32{ w, h, 1.0 };
        glm.glm_scale_make(&scaling, &scale_vec[0]);

        // Combine scaling and translation into transform matrix
        transform = mat4_mul(scaling, translation);
        // --------------

        // Uniforms
        if (prevColor[0..] != settings.color[0..]) {
            prevColor = settings.color;

            const color = prevColor;
            gl.glUniform4fv(gl.glGetUniformLocation(settings.shader.shaderProgram, "aColor"), 1, &[4]f32{
                @floatFromInt(color[0]),
                @floatFromInt(color[1]),
                @floatFromInt(color[2]),
                @floatFromInt(color[3]),
            });
        }

        if (settings.texture) |texture| {
            if (prevTexture != texture) {
                prevTexture = texture;

                settings.shader.setUniformInt("useTexture", 1);
                settings.shader.setUniformInt("aTexture", 0);
                texture.bind(gl.GL_TEXTURE0);
            }
        } else {
            prevTexture = undefined;
            settings.shader.setUniformInt("useTexture", 0);
        }

        switch (settings.camera) {
            Camera.Orthographic => {
                projection = getOrthoProjection();

                var view_vec: [3]f32 = [3]f32{ 0, 0, 0.0 };
                glm.glm_translate_make(&view, &view_vec[0]);
            },
            Camera.Perspective => {
                projection = getPerspectiveProjection();
                view = getPerspView();
            },
        }

        settings.shader.setUniformM4("projection", projection);
        settings.shader.setUniformM4("view", view);
        settings.shader.setUniformM4("transform", transform);

        // Drawing
        gl.glBindVertexArray(VAO);
        switch (settings.drawMode) {
            DrawMode.FILL => {
                self.drawShape();
            },
            DrawMode.LINE => {
                // Draw wireframe shape
                gl.glPolygonMode(gl.GL_FRONT_AND_BACK, gl.GL_LINE);
                self.drawShape();
                gl.glPolygonMode(gl.GL_FRONT_AND_BACK, gl.GL_FILL);
            },
        }
        gl.glBindVertexArray(0);
    }

    fn drawShape(self: *ShapeBuilder) void {
        if (self.indices.len > 0) {
            // Draw using indices
            gl.glDrawElements(gl.GL_TRIANGLES, @intCast(self.indices.len), gl.GL_UNSIGNED_INT, null);
        } else {
            // Draw using vertices
            gl.glDrawArrays(gl.GL_TRIANGLES, 0, @intCast(self.vertices.len));
        }
    }
};

pub const Shape = struct {
    // ------------------------------
    pub fn rectangle() ShapeBuilder {
        const vertices = &[_]Vertex{
            Vertex{
                .position = [3]f32{ 0.0, 1.0, 0.0 },
                .uv = [2]f32{ 0.0, 0.0 },
            },
            Vertex{
                .position = [3]f32{ 1.0, 1.0, 0.0 },
                .uv = [2]f32{ 1.0, 0.0 },
            },
            Vertex{
                .position = [3]f32{ 0.0, 0.0, 0.0 },
                .uv = [2]f32{ 0.0, 1.0 },
            },
            Vertex{
                .position = [3]f32{ 1.0, 0.0, 0.0 },
                .uv = [2]f32{ 1.0, 1.0 },
            },
        };

        const indices = &[_]u32{ 0, 1, 2, 1, 3, 2 };

        return ShapeBuilder.init(vertices, indices);
    }

    // ------------------------------
    pub fn triangle() ShapeBuilder {
        const vertices = &[_]Vertex{
            Vertex{
                .position = [3]f32{ 0.5, 0.0, 0.0 },
                .uv = [2]f32{ 0.5, 1.0 },
            },
            Vertex{
                .position = [3]f32{ 0.0, 1.0, 0.0 },
                .uv = [2]f32{ 0.0, 0.0 },
            },
            Vertex{
                .position = [3]f32{ 1.0, 1.0, 0.0 },
                .uv = [2]f32{ 1.0, 0.0 },
            },
        };

        return ShapeBuilder.init{ vertices, &.{} };
    }

    pub fn cube() ShapeBuilder {
        const vertices = &[_]Vertex{
            // Front face
            Vertex{ .position = [3]f32{ 0.0, 1.0, 1.0 }, .uv = [2]f32{ 0.0, 1.0 } },
            Vertex{ .position = [3]f32{ 1.0, 1.0, 1.0 }, .uv = [2]f32{ 1.0, 1.0 } },
            Vertex{ .position = [3]f32{ 0.0, 0.0, 1.0 }, .uv = [2]f32{ 0.0, 0.0 } },
            Vertex{ .position = [3]f32{ 1.0, 0.0, 1.0 }, .uv = [2]f32{ 1.0, 0.0 } },

            // Back face
            Vertex{ .position = [3]f32{ 0.0, 1.0, 0.0 }, .uv = [2]f32{ 0.0, 1.0 } },
            Vertex{ .position = [3]f32{ 1.0, 1.0, 0.0 }, .uv = [2]f32{ 1.0, 1.0 } },
            Vertex{ .position = [3]f32{ 0.0, 0.0, 0.0 }, .uv = [2]f32{ 0.0, 0.0 } },
            Vertex{ .position = [3]f32{ 1.0, 0.0, 0.0 }, .uv = [2]f32{ 1.0, 0.0 } },

            // Top face
            Vertex{ .position = [3]f32{ 0.0, 1.0, 0.0 }, .uv = [2]f32{ 0.0, 1.0 } },
            Vertex{ .position = [3]f32{ 1.0, 1.0, 0.0 }, .uv = [2]f32{ 1.0, 1.0 } },
            Vertex{ .position = [3]f32{ 0.0, 1.0, 1.0 }, .uv = [2]f32{ 0.0, 0.0 } },
            Vertex{ .position = [3]f32{ 1.0, 1.0, 1.0 }, .uv = [2]f32{ 1.0, 0.0 } },

            // Bottom face
            Vertex{ .position = [3]f32{ 0.0, 0.0, 0.0 }, .uv = [2]f32{ 0.0, 1.0 } },
            Vertex{ .position = [3]f32{ 1.0, 0.0, 0.0 }, .uv = [2]f32{ 1.0, 1.0 } },
            Vertex{ .position = [3]f32{ 0.0, 0.0, 1.0 }, .uv = [2]f32{ 0.0, 0.0 } },
            Vertex{ .position = [3]f32{ 1.0, 0.0, 1.0 }, .uv = [2]f32{ 1.0, 0.0 } },
        };

        const indices = &[_]u32{
            // Front face
            0,  1,  2,  1,  3,  2,

            // Back face
            4,  5,  6,  5,  7,  6,

            // Top face
            8,  9,  10, 9,  11, 10,

            // Bottom face
            12, 13, 14, 13, 15, 14,

            // Left face
            0,  4,  2,  4,  6,  2,

            // Right face
            1,  5,  3,  5,  7,  3,
        };

        return ShapeBuilder.init(vertices, indices);
    }
};

// ------------------------------
fn getOrthoProjection() [4][4]f32 {
    var a: [4][4]f32 align(16) = undefined;
    glm.glm_ortho(0, 1280, 720, 0, -1, 1, &a);
    return a;
}

// ------------------------------
fn getPerspectiveProjection() [4][4]f32 {
    var a: [4][4]f32 align(16) = undefined;
    glm.glm_perspective(std.math.degreesToRadians(Camera.fov), Camera.aspect, Camera.near, Camera.far, &a);
    return a;
}

// ------------------------------
fn getPerspView() [4][4]f32 {
    var view: [4][4]f32 align(16) = undefined;
    var target_position = [3]f32{
        Camera.position[0] + Camera.direction[0],
        Camera.position[1] + Camera.direction[1],
        Camera.position[2] + Camera.direction[2],
    };
    var up_vector: [3]f32 = [3]f32{ 0, 1, 0 };

    glm.glm_lookat(&Camera.position[0], &target_position[0], &up_vector[0], &view);

    return view;
}
