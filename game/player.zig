const maskot = @import("../maskot/maskot.zig");
const window = @import("../maskot/maskot.zig").window;

pub const Player = struct {
    texture: maskot.texture.Texture,
    shape: maskot.shape.ShapeBuilder,
    camera: [2]f32,
    position: [2]f32,

    pub fn init() !Player {
        return Player{
            .texture = try maskot.texture.Texture.fromFile("assets/lol-face.png", .{}),
            .shape = maskot.shape.Shape.rectangle(),
            .camera = [2]f32{ 0, 0 },
            .position = [2]f32{ 0, 0 },
        };
    }

    pub fn deinit(self: *Player) void {
        self.texture.destroy();
        self.shape.deinit();
    }

    pub fn update(self: *Player) void {
        self.shape.draw(self.position[0] - self.camera[0], self.position[1] - self.camera[1], 32, 32, .{
            .texture = &self.texture,
        });

        const speed: f32 = 4;
        if (window.isKeyDown(window.glfw.GLFW_KEY_W)) self.position[1] -= speed;
        if (window.isKeyDown(window.glfw.GLFW_KEY_S)) self.position[1] += speed;
        if (window.isKeyDown(window.glfw.GLFW_KEY_A)) self.position[0] -= speed;
        if (window.isKeyDown(window.glfw.GLFW_KEY_D)) self.position[0] += speed;

        self.camera[0] += ((self.position[0] + 32 / 2) - self.camera[0] - window.getSize()[0] / 2) / 12;
        self.camera[1] += ((self.position[1] + 32 / 2) - self.camera[1] - window.getSize()[1] / 2) / 12;
    }
};
