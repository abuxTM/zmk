const std = @import("std");
const maskot = @import("../maskot/maskot.zig");
const window = @import("../maskot/maskot.zig").window;
const ishape = @import("../maskot/maskot.zig").shape;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

var nextID: u32 = 0;

pub const World = struct {
    transforms: std.AutoHashMap(u32, Transform),
    drawables: std.AutoHashMap(u32, Drawable),
    entities: std.AutoHashMap(u32, EntityType),

    pub fn init() World {
        return World{
            .transforms = std.AutoHashMap(u32, Transform).init(allocator),
            .drawables = std.AutoHashMap(u32, Drawable).init(allocator),
            .entities = std.AutoHashMap(u32, EntityType).init(allocator),
        };
    }

    pub fn deinit(self: *World) void {
        self.transforms.deinit();
        self.drawables.deinit();
        self.entities.deinit();
    }

    // --------------------------------
    pub fn render(self: *World, camera: [2]f32) void {
        var transform_iter = self.transforms.iterator();
        while (transform_iter.next()) |entry| {
            const entity_id = entry.key_ptr.*;
            const transform = entry.value_ptr.*;

            // Calculate the entity's screen position relative to the camera
            const screen_x = transform.position[0] - camera[0];
            const screen_y = transform.position[1] - camera[1];

            // Check if the entity is within the camera's boundaries
            if (screen_x + transform.size[0] < 0 or screen_x > window.getSize()[0] or
                screen_y + transform.size[1] < 0 or screen_y > window.getSize()[1])
            {
                continue;
            }

            // Retrieve drawable component and draw if available
            var drawable_get = self.drawables.get(entity_id);
            if (drawable_get) |*drawable| {
                drawable.shape.draw(
                    screen_x,
                    screen_y,
                    transform.size[0],
                    transform.size[1],
                    drawable.settings,
                );
            }
        }
    }

    // --------------------------------
    pub fn update(self: *World, camera: *[2]f32) void {
        const speed: f32 = 4;

        var transform_iter = self.transforms.iterator();
        while (transform_iter.next()) |entry| {
            const entity_id = entry.key_ptr.*;
            const transform = entry.value_ptr;

            // Check if the entity is a Player
            if (self.entities.get(entity_id) == EntityType.Player) {
                // Update position based on keyboard input
                if (window.isKeyDown(window.glfw.GLFW_KEY_W)) transform.position[1] -= speed;
                if (window.isKeyDown(window.glfw.GLFW_KEY_S)) transform.position[1] += speed;
                if (window.isKeyDown(window.glfw.GLFW_KEY_A)) transform.position[0] -= speed;
                if (window.isKeyDown(window.glfw.GLFW_KEY_D)) transform.position[0] += speed;

                // Update camera to follow the player
                camera[0] += ((transform.position[0] + (transform.size[0] / 2) / 2) - camera[0] - window.getSize()[0] / 2) / 12;
                camera[1] += ((transform.position[1] + ((transform.size[1] / 2) + 40) / 2) - camera[1] - window.getSize()[1] / 2) / 12;
            }
        }
    }

    // --------------------------------
    pub fn addEntity(self: *World, entityType: EntityType, components: Components) !void {
        try self.entities.put(nextID, entityType);

        if (components.transform) |t| {
            try self.transforms.put(nextID, t);
        }

        if (components.drawable) |d| {
            try self.drawables.put(nextID, d);
        }

        nextID += 1;
    }
};

const EntityType = enum {
    Player,
    Tile,
};

pub const Components = struct {
    transform: ?Transform = null,
    velocity: ?Velocity = null,
    drawable: ?Drawable = null,
};

const Direction = enum {
    UP,
    DOWN,
    LEFT,
    RIGHT,
};

const Transform = struct {
    position: [2]f32,
    size: [2]f32,
    rotation: f32,
};

const Velocity = struct {
    dir: [2]f32,
    friction: f32,
};

const Drawable = struct {
    shape: maskot.shape.ShapeBuilder,
    settings: maskot.shape.DrawSettings,
};
