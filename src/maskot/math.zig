const std = @import("std");
const gl = @cImport(@cInclude("glad.h"));

pub const Vertex = struct {
    position: Vector3D(f32),
    uv: ?Vector2D(f32) = null,

    pub fn setAttributes(vertex: *const Vertex) void {
        var offset: usize = 0;

        // Position
        // -------------
        gl.glVertexAttribPointer(0, 3, gl.GL_FLOAT, gl.GL_FALSE, @sizeOf(Vertex), @ptrFromInt(offset));
        gl.glEnableVertexAttribArray(0);
        offset += @sizeOf(Vector3D(f32));

        // UV
        // -------------
        if (vertex.uv != null) {
            gl.glVertexAttribPointer(1, 2, gl.GL_FLOAT, gl.GL_FALSE, @sizeOf(Vertex), @ptrFromInt(offset));
            gl.glEnableVertexAttribArray(1);
            offset += @sizeOf(Vector2D(f32));
        }
    }
};

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8 = 255.0,

    pub fn init(r: u8, g: u8, b: u8, a: u8) Color {
        return Color{
            .r = r,
            .g = g,
            .b = b,
            .a = a,
        };
    }
};

pub fn Vector3D(comptime T: type) type {
    return struct {
        x: T,
        y: T,
        z: T,

        pub fn init(x: T, y: T, z: T) Vector3D(T) {
            return Vector3D(T){ .x = x, .y = y, .z = z };
        }

        pub fn zero() Vector3D(T) {
            return Vector3D(T){ .x = 0, .y = 0, .z = 0 };
        }
    };
}

pub fn Vector2D(comptime T: type) type {
    return struct {
        x: T,
        y: T,

        pub fn init(x: T, y: T) Vector2D(T) {
            return Vector2D(T){ .x = x, .y = y };
        }

        pub fn zero() Vector2D(T) {
            return Vector2D(T){ .x = 0, .y = 0 };
        }

        // Vector addition
        pub fn add(self: Vector2D(T), other: Vector2D(T)) Vector2D(T) {
            return Vector2D(T).init(self.x + other.x, self.y + other.y);
        }

        // Vector subtraction
        pub fn subtract(self: Vector2D(T), other: Vector2D(T)) Vector2D(T) {
            return Vector2D(T).init(self.x - other.x, self.y - other.y);
        }

        // Scalar multiplication
        pub fn scale(self: Vector2D(T), scalar: T) Vector2D(T) {
            return Vector2D(T).init(self.x * scalar, self.y * scalar);
        }

        // Dot product
        pub fn dot(self: Vector2D(T), other: Vector2D(T)) T {
            return self.x * other.x + self.y * other.y;
        }

        // Magnitude (length) of the vector
        pub fn magnitude(self: Vector2D(T)) T {
            return @sqrt(self.x * self.x + self.y * self.y);
        }

        // Normalization (for floating-point vectors)
        pub fn normalize(self: Vector2D(T)) Vector2D(T) {
            const mag = self.magnitude();
            return if (mag != 0) self.scale(1 / mag) else self;
        }

        // Print vector (for debugging)
        pub fn print(self: Vector2D(T)) void {
            std.debug.print("Vector2D(T)({}, {})\n", .{ self.x, self.y });
        }
    };
}

// ------------------------------
pub fn ortho(width: f32, height: f32, near: f32, far: f32) [4][4]f32 {
    var result: [4][4]f32 = undefined;

    result[0][0] = 2.0 / width;
    result[1][1] = -2.0 / height; // Flip the Y-axis
    result[2][2] = -2.0 / (far - near);
    result[3][3] = 1.0;

    result[3][0] = -1.0;
    result[3][1] = 1.0;
    result[3][2] = -(far + near) / (far - near);

    return result;
}

// ------------------------------
pub fn translation_2d(x: f32, y: f32) [4][4]f32 {
    return .{ .{ 1.0, 0.0, 0.0, 0.0 }, .{ 0.0, 1.0, 0.0, 0.0 }, .{ 0.0, 0.0, 1.0, 0.0 }, .{ x, y, 0.0, 1.0 } };
}

// ------------------------------
pub fn scaling_2d(sx: f32, sy: f32) [4][4]f32 {
    return .{ .{ sx, 0.0, 0.0, 0.0 }, .{ 0.0, sy, 0.0, 0.0 }, .{ 0.0, 0.0, 1.0, 0.0 }, .{ 0.0, 0.0, 0.0, 1.0 } };
}

// ------------------------------
pub fn multiply_matrices(a: [4][4]f32, b: [4][4]f32) [4][4]f32 {
    var result: [4][4]f32 = undefined;
    for (0..4) |i| {
        for (0..4) |j| {
            result[i][j] = a[i][0] * b[0][j] +
                a[i][1] * b[1][j] +
                a[i][2] * b[2][j] +
                a[i][3] * b[3][j];
        }
    }
    return result;
}
