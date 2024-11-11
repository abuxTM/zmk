const maskot = @import("../maskot/maskot.zig");

pub const Item = struct {
    texture: maskot.texture.Texture,
    shape: maskot.shape.ShapeBuilder,
    position: [2]f32,

    pub fn init() !Item {
        return Item{
            .texture = try maskot.texture.Texture.fromFile("assets/outline.png", .{}),
            .shape = maskot.shape.Shape.rectangle(),
            .position = [2]f32{ 0, 0 },
        };
    }

    pub fn deinit(self: *Item) void {
        self.texture.destroy();
        self.shape.deinit();
    }

    pub fn update(self: *Item, camera: [2]f32) void {
        self.shape.draw(self.position[0] - camera[0], self.position[1] - camera[1], 32, 32, .{
            .texture = &self.texture,
        });
    }
};
