const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    const minhook = b.dependency("minhook", .{});

    const lib = b.addStaticLibrary(.{
        .name = "minhook",
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    });

    lib.linkLibC();
    lib.addIncludePath(minhook.path("include"));
    lib.addCSourceFile(.{ .file = minhook.path("src/buffer.c"), .flags = &.{} });
    lib.addCSourceFile(.{ .file = minhook.path("src/hook.c"), .flags = &.{} });
    lib.addCSourceFile(.{ .file = minhook.path("src/trampoline.c"), .flags = &.{} });
    lib.addCSourceFile(.{ .file = minhook.path("src/hde/hde32.c"), .flags = &.{} });
    lib.addCSourceFile(.{ .file = minhook.path("src/hde/hde64.c"), .flags = &.{} });

    b.installArtifact(lib);

    _ = b.addModule("minhook", .{ .source_file = .{ .path = "minhook.zig" } });

    const minhook_test = b.addTest(.{
        .name = "minhook-test",
        .root_source_file = .{ .path = "minhook.zig" },
    });

    minhook_test.linkLibrary(lib);

    const test_step = b.step("test", "test minhook bindings");
    test_step.dependOn(&b.addRunArtifact(minhook_test).step);
}
