const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Build the Rust dia-core library
    const dia_core_lib = b.addSharedLibrary(.{
        .name = "dia_core",
        .target = target,
        .optimize = optimize,
    });

    // Add Rust build step
    const cargo_build = b.addSystemCommand(&[_][]const u8{
        "cargo", "build", "--release",
    });
    dia_core_lib.step.dependOn(&cargo_build.step);

    // Add the Rust library to the linker
    dia_core_lib.addLibraryPath(.{ .path = "target/release" });
    dia_core_lib.linkSystemLibrary("dia_core");

    // Install the library
    b.installArtifact(dia_core_lib);

    // Example executables
    const hello_world = b.addExecutable(.{
        .name = "hello_world",
        .root_source_file = .{ .path = "examples/hello_world.zig" },
        .target = target,
        .optimize = optimize,
    });
    hello_world.addIncludePath(.{ .path = "src" });
    hello_world.linkLibrary(dia_core_lib);
    hello_world.linkLibC();

    const rest_api = b.addExecutable(.{
        .name = "rest_api",
        .root_source_file = .{ .path = "examples/rest_api.zig" },
        .target = target,
        .optimize = optimize,
    });
    rest_api.addIncludePath(.{ .path = "src" });
    rest_api.linkLibrary(dia_core_lib);
    rest_api.linkLibC();

    // Install examples
    b.installArtifact(hello_world);
    b.installArtifact(rest_api);

    // Run commands
    const run_hello = b.addRunArtifact(hello_world);
    const run_rest = b.addRunArtifact(rest_api);

    const run_hello_step = b.step("run-hello", "Run the hello world example");
    run_hello_step.dependOn(&run_hello.step);

    const run_rest_step = b.step("run-rest", "Run the REST API example");
    run_rest_step.dependOn(&run_rest.step);

    // Tests
    const test_step = b.step("test", "Run tests");
    
    const cargo_test = b.addSystemCommand(&[_][]const u8{
        "cargo", "test",
    });
    test_step.dependOn(&cargo_test.step);
}