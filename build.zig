const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Build dia-core Rust library
    const build_rust = b.addSystemCommand(&[_][]const u8{
        "cargo", "build", "--release", "-p", "dia-core"
    });

    // Create the dia module
    const dia_mod = b.addModule("dia", .{
        .root_source_file = b.path("src/dia.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Create a static library for dia
    const dia_lib = b.addStaticLibrary(.{
        .name = "dia",
        .root_source_file = b.path("src/dia.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Link with the Rust library
    dia_lib.addLibraryPath(b.path("target/release"));
    dia_lib.linkSystemLibrary("dia_core");
    dia_lib.linkLibC();

    // Add build dependency
    dia_lib.step.dependOn(&build_rust.step);

    b.installArtifact(dia_lib);

    // Create test executable
    const test_exe = b.addExecutable(.{
        .name = "dia_test",
        .root_source_file = b.path("examples/test_connection.zig"),
        .target = target,
        .optimize = optimize,
    });

    test_exe.root_module.addImport("dia", dia_mod);
    test_exe.addLibraryPath(b.path("target/release"));
    test_exe.linkSystemLibrary("dia_core");
    test_exe.linkLibC();
    test_exe.step.dependOn(&build_rust.step);

    const test_install = b.addInstallArtifact(test_exe, .{});
    const test_step = b.step("test-connection", "Build and install test connection executable");
    test_step.dependOn(&test_install.step);

    // Hello World example
    const hello_exe = b.addExecutable(.{
        .name = "hello_world",
        .root_source_file = b.path("examples/hello_world.zig"),
        .target = target,
        .optimize = optimize,
    });

    hello_exe.root_module.addImport("dia", dia_mod);
    hello_exe.addLibraryPath(b.path("target/release"));
    hello_exe.linkSystemLibrary("dia_core");
    hello_exe.linkLibC();
    hello_exe.step.dependOn(&build_rust.step);

    const hello_install = b.addInstallArtifact(hello_exe, .{});
    const hello_step = b.step("hello", "Build and install Hello World example");
    hello_step.dependOn(&hello_install.step);

    // REST API example
    const api_exe = b.addExecutable(.{
        .name = "rest_api",
        .root_source_file = b.path("examples/rest_api.zig"),
        .target = target,
        .optimize = optimize,
    });

    api_exe.root_module.addImport("dia", dia_mod);
    api_exe.addLibraryPath(b.path("target/release"));
    api_exe.linkSystemLibrary("dia_core");
    api_exe.linkLibC();
    api_exe.step.dependOn(&build_rust.step);

    const api_install = b.addInstallArtifact(api_exe, .{});
    const api_step = b.step("api", "Build and install REST API example");
    api_step.dependOn(&api_install.step);

    // Run examples
    const run_hello = b.addRunArtifact(hello_exe);
    const run_hello_step = b.step("run-hello", "Run Hello World example");
    run_hello_step.dependOn(&run_hello.step);

    const run_api = b.addRunArtifact(api_exe);
    const run_api_step = b.step("run-api", "Run REST API example");
    run_api_step.dependOn(&run_api.step);

    const run_test = b.addRunArtifact(test_exe);
    const run_test_step = b.step("run-test", "Run connection test");
    run_test_step.dependOn(&run_test.step);
}