const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;
const NativePaths = std.zig.system.NativePaths;

pub fn getNixFlags(allocator: std.mem.Allocator) ?NativePaths {
    if (std.process.hasEnvVarConstant("NIX_CFLAGS_COMPILE") or std.process.hasEnvVarConstant("NIX_LDFLAGS")) {
        // we don't actually care what this is. it's not used by the nix detection code
        const garbage_nti = std.zig.system.NativeTargetInfo{ .target = builtin.target, .dynamic_linker = std.zig.system.NativeTargetInfo.DynamicLinker.init(null) };
        return NativePaths.detect(allocator, garbage_nti) catch unreachable;
    }
    return null;
}

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zig-pkg",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "main.c" },
        .target = target,
        .optimize = optimize,
    });
    exe.linkSystemLibrary("config");
    exe.linkLibC();

    if (getNixFlags(arena.allocator())) |paths| {
        for (paths.warnings.items) |warning| {
            std.log.warn("{s}", .{warning});
        }
        for (paths.include_dirs.items) |include_dir| {
            exe.addIncludePath(include_dir);
        }
        for (paths.framework_dirs.items) |framework_dir| {
            exe.addFrameworkPath(framework_dir);
        }
        for (paths.lib_dirs.items) |lib_dir| {
            exe.addLibraryPath(lib_dir);
        }
        for (paths.rpaths.items) |rpath| {
            exe.addRPath(rpath);
        }
    }

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    exe.install();
}
