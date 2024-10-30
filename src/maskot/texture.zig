const std = @import("std");
const gl = @cImport(@cInclude("glad.h"));
const stb = @cImport(@cInclude("stb_image.h"));

pub const Texture = struct {
    id: gl.GLuint,
    width: i32,
    height: i32,

    /// Load an image as an OpenGL texture.
    pub fn fromFile(path: []const u8) !Texture {
        var width: i32 = 0;
        var height: i32 = 0;
        var channels: i32 = 0;

        // Load image using stb_image
        stb.stbi_set_flip_vertically_on_load(1); // Flip vertically for OpenGL
        const data = stb.stbi_load(path.ptr, &width, &height, &channels, 4); // Force RGBA
        if (data == null) {
            std.debug.print("File not found: {s}\n", .{path});
            return undefined;
        }
        defer stb.stbi_image_free(data);

        // Generate OpenGL texture
        var texture_id: gl.GLuint = 0;
        gl.glGenTextures(1, &texture_id);
        gl.glBindTexture(gl.GL_TEXTURE_2D, texture_id);

        // Set texture parameters
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE);
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE);
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR);
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR);

        // Upload texture data
        gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA8, width, height, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, data);
        gl.glGenerateMipmap(gl.GL_TEXTURE_2D);

        // Unbind texture
        gl.glBindTexture(gl.GL_TEXTURE_2D, 0);

        return Texture{
            .id = texture_id,
            .width = width,
            .height = height,
        };
    }

    /// Bind the texture for use in OpenGL
    pub fn bind(self: *Texture, unit: gl.GLenum) void {
        gl.glActiveTexture(unit);
        gl.glBindTexture(gl.GL_TEXTURE_2D, self.id);
    }

    /// Release the OpenGL texture when done
    pub fn destroy(self: *Texture) void {
        gl.glDeleteTextures(1, &self.id);
    }
};
