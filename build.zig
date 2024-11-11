const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "maskot",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .use_llvm = false,
        .use_lld = false,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    exe.linkLibC();
    exe.linkLibCpp();
    exe.addIncludePath(b.path("src/vendors"));
    exe.addIncludePath(b.path("src/vendors/imgui"));

    exe.addCSourceFiles(.{
        .root = b.path("src/vendors"),
        .files = &.{
            "glad.c",
            "stb_image.c",
        },
        .flags = &.{"-g"},
    });

    exe.linkSystemLibrary("gl");
    exe.linkSystemLibrary("cglm");
    exe.linkSystemLibrary("glfw");
}
