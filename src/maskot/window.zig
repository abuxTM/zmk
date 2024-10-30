const std = @import("std");
pub const glfw = @cImport(@cInclude("GLFW/glfw3.h"));
const gl = @cImport(@cInclude("glad.h"));

const maskot = @import("maskot.zig");
const math = @import("maskot.zig").math;

var keyStates: [glfw.GLFW_KEY_LAST]bool = undefined;

var window: *glfw.GLFWwindow = undefined;
var size = math.Vector2D(f32).zero();
pub var shader: maskot.shader.MKShader = undefined;

pub fn createWindow(title: [*c]const u8, width: i32, height: i32) !void {
    _ = glfw.glfwInit();

    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MINOR, 3);
    glfw.glfwWindowHint(glfw.GLFW_OPENGL_PROFILE, glfw.GLFW_OPENGL_CORE_PROFILE);

    size = math.Vector2D(f32).init(@floatFromInt(width), @floatFromInt(height));

    window = glfw.glfwCreateWindow(width, height, title, null, null) orelse {
        glfw.glfwTerminate();
        return error.WindowCreationFailed;
    };

    glfw.glfwMakeContextCurrent(window);

    // Initialize GLAD to load OpenGL functions
    const get_proc_address: gl.GLADloadproc = @ptrCast(&glfw.glfwGetProcAddress);
    if (gl.gladLoadGLLoader(get_proc_address) == 0) {
        glfw.glfwDestroyWindow(window);
        glfw.glfwTerminate();
        return error.GladInitializationFailed;
    }

    gl.glViewport(0, 0, width, height);
    gl.glEnable(gl.GL_BLEND);

    // ---
    shader = try maskot.shader.MKShader.init();
}

pub fn close() void {
    defer shader.deinit();
    glfw.glfwDestroyWindow(window);
    glfw.glfwTerminate();
}

// Window should close
// ------------------------------
pub fn shouldClose() bool {
    return glfw.glfwWindowShouldClose(window) != 0;
}

// ------------------------------
pub fn getSize() math.Vector2D(f32) {
    return size;
}

// ------------------------------
pub fn getOrthoProjection() [4][4]f32 {
    return math.ortho(size.x, size.y, -1, 1);
}

// Sets background color
// ------------------------------
pub fn setClearColor(r: f32, g: f32, b: f32) void {
    glfw.glClearColor(r / 255, g / 255, b / 255, 1.0);
}

// Clears the window for next buffer
// ------------------------------
pub fn beginDrawing() void {
    glfw.glClear(glfw.GL_COLOR_BUFFER_BIT);
    glfw.glfwPollEvents();

    // Use the shader program
    gl.glUseProgram(shader.shaderProgram);
}

// Swaps buffers
// ------------------------------
pub fn endDrawing() void {
    glfw.glfwSwapBuffers(window);
}

// Checks if specific key have been pressed
// ------------------------------
pub fn isKeyDown(key: i32) bool {
    return glfw.glfwGetKey(window, key) == glfw.GLFW_PRESS;
}

// It does exactly what you think it does
// ------------------------------
pub fn isKeyPressed(key: i32) bool {
    const index: usize = @intCast(key);

    const currentState = glfw.glfwGetKey(window, key);
    const previouslyPressed = keyStates[index];

    keyStates[index] = currentState == glfw.GLFW_PRESS;

    return currentState == glfw.GLFW_PRESS and !previouslyPressed;
}