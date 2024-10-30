const maskot = @import("maskot/maskot.zig");
const window = @import("maskot/maskot.zig").window;
const utils = @import("maskot/maskot.zig").texture;
const shape = @import("maskot/maskot.zig").shape;
const math = @import("maskot/maskot.zig").math;

// TODO: Organiz
// TODO: Add Texture Settings (Optional Transparency and etc)
// TODO: Optimize shape drawing by only setting the uniforms if values actualy change instead of per-frame
// TODO: Turn this into lib
// FIX: C-GLM Math Library No Wok D:

pub fn main() !void {
    try window.createWindow("Maskot", 1280, 720);
    defer window.close();

    var rect = shape.Shape.rectangle();
    defer rect.deinit();

    var camera = math.Vector2D(f32).init(0, 0);

    var texture = try utils.Texture.fromFile("assets/lol-face.png");
    defer texture.destroy();

    while (!window.shouldClose()) {
        window.setClearColor(20, 20, 20);
        window.beginDrawing();

        const speed: f32 = 6;
        if (window.isKeyDown(window.glfw.GLFW_KEY_W)) camera.y -= speed;
        if (window.isKeyDown(window.glfw.GLFW_KEY_S)) camera.y += speed;
        if (window.isKeyDown(window.glfw.GLFW_KEY_A)) camera.x -= speed;
        if (window.isKeyDown(window.glfw.GLFW_KEY_D)) camera.x += speed;

        for (0..@intFromFloat(window.getSize().x / 64)) |x| {
            const xx: f32 = @floatFromInt(x);
            rect.draw((xx * 64) - camera.x, (window.getSize().y - 64.0) - camera.y, 64, 64, shape.DrawSettings{
                .color = math.Color.init(200, 200, 200, 200),
                .texture = &texture,
                .shader = &window.shader,
                // .drawMode = shape.DrawMode.LINE,
                .projection = window.getOrthoProjection(),
            });
        }

        window.endDrawing();
    }
}
