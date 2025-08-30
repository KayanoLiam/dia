const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // === Dia Framework Module ===

    // Create the dia module for easy import
    const dia_module = b.addModule("dia", .{
        .source_file = .{ .path = "src/dia.zig" },
    });

    // Build the Rust dia-core library
    const dia_core_lib = buildRustLibrary(b, target, optimize);

    // === Examples ===

    // Hello World example
    const hello_world = b.addExecutable(.{
        .name = "hello_world",
        .root_source_file = .{ .path = "examples/hello_world.zig" },
        .target = target,
        .optimize = optimize,
    });
    hello_world.addModule("dia", dia_module);
    hello_world.linkLibrary(dia_core_lib);
    hello_world.linkLibC();

    // REST API example
    const rest_api = b.addExecutable(.{
        .name = "rest_api",
        .root_source_file = .{ .path = "examples/rest_api.zig" },
        .target = target,
        .optimize = optimize,
    });
    rest_api.addModule("dia", dia_module);
    rest_api.linkLibrary(dia_core_lib);
    rest_api.linkLibC();

    // Install examples
    b.installArtifact(hello_world);
    b.installArtifact(rest_api);

    // === Run Commands ===

    const run_hello = b.addRunArtifact(hello_world);
    const run_rest = b.addRunArtifact(rest_api);

    const run_hello_step = b.step("run-hello", "Run the hello world example");
    run_hello_step.dependOn(&run_hello.step);

    const run_rest_step = b.step("run-rest", "Run the REST API example");
    run_rest_step.dependOn(&run_rest.step);

    // === Tests ===

    const test_step = b.step("test", "Run all tests");

    // Rust tests
    const cargo_test = b.addSystemCommand(&[_][]const u8{
        "cargo", "test",
    });
    test_step.dependOn(&cargo_test.step);

    // Zig tests
    const zig_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/dia.zig" },
        .target = target,
        .optimize = optimize,
    });
    zig_tests.linkLibrary(dia_core_lib);
    zig_tests.linkLibC();

    const run_zig_tests = b.addRunArtifact(zig_tests);
    test_step.dependOn(&run_zig_tests.step);

    // === Development Tools ===

    // Build only Rust components
    const build_rust_step = b.step("build-rust", "Build only Rust components");
    build_rust_step.dependOn(&dia_core_lib.step);

    // Clean build artifacts
    const clean_step = b.step("clean", "Clean build artifacts");
    const clean_rust = b.addSystemCommand(&[_][]const u8{
        "cargo", "clean",
    });
    clean_step.dependOn(&clean_rust.step);
}

/// Build the Rust dia-core library
fn buildRustLibrary(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    // Build Rust library with appropriate profile
    const build_mode = if (optimize == .Debug) "dev" else "release";
    const cargo_build = b.addSystemCommand(&[_][]const u8{
        "cargo", "build", "--profile", build_mode,
    });

    // Create a shared library target
    const dia_core_lib = b.addSharedLibrary(.{
        .name = "dia_core",
        .target = target,
        .optimize = optimize,
    });

    // Depend on Rust build
    dia_core_lib.step.dependOn(&cargo_build.step);

    // Add the Rust library path
    const lib_dir = if (optimize == .Debug) "target/debug" else "target/release";
    dia_core_lib.addLibraryPath(.{ .path = lib_dir });

    // Link the Rust library
    dia_core_lib.linkSystemLibrary("dia_core");

    // Install the library
    b.installArtifact(dia_core_lib);

    return dia_core_lib;
}
