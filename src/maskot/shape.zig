const std = @import("std");
const gl = @cImport(@cInclude("glad.h"));
const stb = @cImport(@cInclude("stb_image.h"));
const maskot = @import("maskot.zig");
const utils = @import("maskot.zig").texture;
const math = @import("maskot.zig").math;

var VAO: gl.GLuint = 0;
var VBO: gl.GLuint = 0;
var EBO: gl.GLuint = 0;

// ------------------------------
pub const DrawMode = enum {
    FILL,
    LINE,
};

// ------------------------------
pub const DrawSettings = struct {
    color: ?math.Color = null,
    texture: ?*utils.Texture = null,
    shader: ?*maskot.shader.MKShader = null,
    drawMode: DrawMode = DrawMode.FILL,
    projection: [4][4]f32,
};

pub const ShapeBuilder = struct {
    vertices: []const math.Vertex,
    indices: []const u32,

    pub fn init(vertices: []const math.Vertex, indices: []const u32) ShapeBuilder {
        // Vertex Array Object (VAO)
        gl.glGenVertexArrays(1, &VAO);
        gl.glBindVertexArray(VAO);

        // Vertex Buffer Object (VBO)
        gl.glGenBuffers(1, &VBO);
        gl.glBindBuffer(gl.GL_ARRAY_BUFFER, VBO);

        // Set buffer data
        const vertices_ptr: *const anyopaque = @ptrCast(vertices.ptr);
        const size: c_long = @intCast(@sizeOf(math.Vertex) * vertices.len);
        gl.glBufferData(gl.GL_ARRAY_BUFFER, size, vertices_ptr, gl.GL_STATIC_DRAW);

        // Set up vertex attribute pointers
        math.Vertex.setAttributes(&vertices[0]);

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
    }

    // ------------------------------
    pub fn draw(self: *ShapeBuilder, x: f32, y: f32, w: f32, h: f32, settings: DrawSettings) void {
        // Setup matrices
        const translation = math.translation_2d(x, y);
        const scale = math.scaling_2d(w, h);
        const transform = math.multiply_matrices(scale, translation);

        // Uniforms
        if (settings.shader) |shader| {
            if (settings.color) |color| {
                gl.glUniform4fv(gl.glGetUniformLocation(shader.shaderProgram, "aColor"), 1, &[4]f32{
                    @floatFromInt(color.r),
                    @floatFromInt(color.g),
                    @floatFromInt(color.b),
                    @floatFromInt(color.a),
                });
            }
            if (settings.texture) |texture| {
                shader.setUniformInt("useTexture", 1);
                shader.setUniformInt("aTexture", 0);
                texture.bind(gl.GL_TEXTURE0);
            } else {
                shader.setUniformInt("useTexture", 0);
            }
            shader.setUniformM4("projection", settings.projection);
            shader.setUniformM4("transform", transform);
        }

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
        const vertices = &[_]math.Vertex{
            math.Vertex{
                .position = math.Vector3D(f32).init(0.0, 1.0, 0.0),
                .uv = math.Vector2D(f32).init(0.0, 0.0),
            },
            math.Vertex{
                .position = math.Vector3D(f32).init(1.0, 1.0, 0.0),
                .uv = math.Vector2D(f32).init(1.0, 0.0),
            },
            math.Vertex{
                .position = math.Vector3D(f32).init(0.0, 0.0, 0.0),
                .uv = math.Vector2D(f32).init(0.0, 1.0),
            },
            math.Vertex{
                .position = math.Vector3D(f32).init(1.0, 0.0, 0.0),
                .uv = math.Vector2D(f32).init(1.0, 1.0),
            },
        };

        const indices = &[_]u32{ 0, 1, 2, 1, 3, 2 };

        return ShapeBuilder.init(vertices, indices);
    }

    // ------------------------------
    pub fn triangle() ShapeBuilder {
        const vertices = &[_]math.Vertex{
            math.Vertex{
                .position = math.Vector3D(f32).init(0.5, 0.0, 0.0),
                .uv = math.Vector2D(f32).init(0.5, 1.0),
            },
            math.Vertex{
                .position = math.Vector3D(f32).init(0.0, 1.0, 0.0),
                .uv = math.Vector2D(f32).init(0.0, 0.0),
            },
            math.Vertex{
                .position = math.Vector3D(f32).init(1.0, 1.0, 0.0),
                .uv = math.Vector2D(f32).init(1.0, 0.0),
            },
        };

        return ShapeBuilder.init(vertices, &.{});
    }
};
