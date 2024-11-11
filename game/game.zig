const std = @import("std");
const World = @import("world.zig");
const Player = @import("player.zig");
const Item = @import("item.zig");

const maskot = @import("../maskot/maskot.zig");
const window = @import("../maskot/maskot.zig").window;
const texture = @import("../maskot/maskot.zig").texture;

const GameSettings = struct {};

pub const Game = struct {
    allocator: std.mem.Allocator,
    assets: std.StringHashMap(texture.Texture),
    items: std.ArrayList(Item.Item),
    camera: [2]f32,

    pub fn init(allocator: std.mem.Allocator) !Game {
        try window.createWindow("Maskot", 1280, 720);

        return Game{
            .allocator = allocator,
            .assets = std.StringHashMap(texture.Texture).init(allocator),
            .items = std.ArrayList(Item.Item).init(allocator),
            .camera = [2]f32{ 0, 0 },
        };
    }

    pub fn deinit(self: *Game) void {
        self.assets.deinit();
        window.close();
    }

    pub fn run(self: *Game) !void {
        try self.assets.put("Tile-0", try texture.Texture.fromFile("assets/outline.png", .{}));

        var player = try Player.Player.init();

        var shape = maskot.shape.Shape.rectangle();
        defer shape.deinit();

        try self.items.append(try Item.Item.init());

        while (!window.shouldClose()) {
            window.setClearColor(20, 20, 20);
            window.beginDrawing();
            defer window.endDrawing();
            // ---

            player.update();

            for (self.items.items) |*item| {
                item.update(player.camera);
            }

            // Set grid size and padding
            const cell_size = 32;
            const padding = 0;
            const grid_size = cell_size + padding;

            const mouse_pos = window.getMousePosition();
            const mouse_x = @as(f32, @floatCast(mouse_pos[0]));
            const mouse_y = @as(f32, @floatCast(mouse_pos[1]));

            // Calculate world coordinates
            const world_x: f32 = mouse_x + self.camera[0];
            const world_y: f32 = mouse_y + self.camera[1];

            // Snap to the nearest grid cell
            const snapped_x: f32 = @floor(world_x / grid_size) * grid_size;
            const snapped_y: f32 = @floor(world_y / grid_size) * grid_size;

            // Draw
            shape.draw(
                snapped_x - self.camera[0],
                snapped_y - self.camera[1],
                cell_size,
                cell_size,
                .{
                    .color = [4]u8{ 11, 11, 11, 100 },
                },
            );
        }
    }
};
